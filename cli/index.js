#!/usr/bin/env node
/**
 * create-wp-ai-plugin
 *
 * Fetches the wp-agentic-kit repo at the requested git ref, runs an
 * interactive interview, then substitutes the example plugin identity
 * with values you provide. See README.md in this package for usage.
 */
import { intro, outro, text, select, confirm, isCancel, cancel, spinner, note } from '@clack/prompts';
import { existsSync, readdirSync, readFileSync, writeFileSync, rmSync, mkdirSync, openSync, closeSync, renameSync } from 'node:fs';
import { readdir } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import { execFileSync, spawn } from 'node:child_process';
import { Readable } from 'node:stream';
import { pipeline } from 'node:stream/promises';
import process from 'node:process';
import * as tar from 'tar';

function spawnLogged(cmd, args, cwd, logPath) {
	// Run a child process, stream stdout + stderr to a log file, resolve
	// when it exits. Returns a promise so the @clack/prompts spinner keeps
	// animating in the event loop while the child runs.
	return new Promise((resolve) => {
		let fd;
		try {
			fd = openSync(logPath, 'w');
		} catch {
			fd = undefined;
		}
		const child = spawn(cmd, args, {
			cwd,
			stdio: ['ignore', fd ?? 'ignore', fd ?? 'ignore'],
		});
		child.on('error', (err) => {
			if (fd !== undefined) { try { closeSync(fd); } catch {} }
			resolve({ ok: false, error: err });
		});
		child.on('exit', (code) => {
			if (fd !== undefined) { try { closeSync(fd); } catch {} }
			resolve({ ok: code === 0, code });
		});
	});
}

const REPO_OWNER = 'pluginslab';
const REPO_NAME = 'wp-agentic-kit';
const DEFAULT_REF = 'main';

const PLACEHOLDER_DESCRIPTION =
	'An example WordPress plugin scaffolded with wp-agentic-kit. Replace this sentence with what your plugin actually does.';
const PLACEHOLDER_AUTHOR = 'Example Author';

const TEXT_EXTENSIONS = new Set([
	'.md', '.php', '.json', '.txt', '.yml', '.yaml',
	'.scss', '.css', '.js', '.ts', '.html', '.xml',
	'.dist',
]);
const SKIP_DIRS = new Set(['.git', 'node_modules', 'vendor', 'build']);
const REMOVE_AFTER_EXTRACT = ['cli', 'docs', '.github'];

function parseArgs(argv) {
	const args = { target: null, ref: DEFAULT_REF, help: false };
	for (let i = 0; i < argv.length; i++) {
		const a = argv[i];
		if (a === '-h' || a === '--help') args.help = true;
		else if (a === '--ref') args.ref = argv[++i];
		else if (!args.target) args.target = a;
	}
	return args;
}

function printHelp() {
	console.log(`Usage: npm create wp-ai-plugin <target-dir> [-- --ref <branch-or-tag>]

Fetches the wp-agentic-kit template at <ref> (default: ${DEFAULT_REF}),
copies it into <target-dir>, and replaces the example plugin identity
with values you choose interactively. <target-dir> is created if it
doesn't exist; it must be empty otherwise.

Examples:
  npm create wp-ai-plugin my-cool-plugin
  npx create-wp-ai-plugin my-cool-plugin
  npm create wp-ai-plugin ../demo -- --ref v0.2.0`);
}

function bail(message) {
	cancel(message);
	process.exit(1);
}

function deriveIdentity(pluginName, vendorPrefix) {
	const slugBase = pluginName.toLowerCase()
		.replace(/[^a-z0-9]+/g, '-')
		.replace(/^-+|-+$/g, '');
	const slug = vendorPrefix ? `${vendorPrefix}-${slugBase}` : slugBase;
	const namespace = slug.split('-')
		.filter(Boolean)
		.map(s => s[0].toUpperCase() + s.slice(1))
		.join('');
	return {
		slug,
		namespace,
		constPrefix: slug.toUpperCase().replace(/-/g, '_'),
		fnPrefix: slug.replace(/-/g, '_'),
	};
}

async function fetchAndExtract(ref, targetDir) {
	const url = `https://codeload.github.com/${REPO_OWNER}/${REPO_NAME}/tar.gz/${encodeURIComponent(ref)}`;
	const res = await fetch(url);
	if (!res.ok || !res.body) {
		throw new Error(`HTTP ${res.status} fetching ${url}`);
	}
	await pipeline(
		Readable.fromWeb(res.body),
		tar.x({ cwd: targetDir, strip: 1 }),
	);
}

async function substitute(targetDir, ctx) {
	let count = 0;
	const replacements = [
		// Order matters: longer / more specific keys first.
		['PL_EXAMPLE', ctx.constPrefix],
		['PLExample', ctx.namespace],
		['pl_example', ctx.fnPrefix],
		['pl-example', ctx.slug],
		['Example Plugin', ctx.pluginName],
		['**WordPress:** 6.7+', `**WordPress:** ${ctx.wpVersion}+`],
		['**PHP:** 8.2+', `**PHP:** ${ctx.phpVersion}+`],
		['"php": ">=8.2"', `"php": ">=${ctx.phpVersion}"`],
		['minimum_supported_wp_version" value="6.7"', `minimum_supported_wp_version" value="${ctx.wpVersion}"`],
		['testVersion" value="8.2-"', `testVersion" value="${ctx.phpVersion}-"`],
	];
	if (ctx.description) {
		replacements.push([PLACEHOLDER_DESCRIPTION, ctx.description]);
	}
	if (ctx.author) {
		replacements.push([PLACEHOLDER_AUTHOR, ctx.author]);
	}

	async function walk(dir) {
		for (const entry of await readdir(dir, { withFileTypes: true })) {
			const p = join(dir, entry.name);
			if (entry.isDirectory()) {
				if (SKIP_DIRS.has(entry.name)) continue;
				await walk(p);
				continue;
			}
			if (!entry.isFile()) continue;
			const dot = entry.name.lastIndexOf('.');
			const ext = dot >= 0 ? entry.name.slice(dot) : '';
			if (!TEXT_EXTENSIONS.has(ext)) continue;

			const original = readFileSync(p, 'utf8');
			let content = original;
			for (const [from, to] of replacements) {
				if (content.includes(from)) content = content.split(from).join(to);
			}
			if (content !== original) {
				writeFileSync(p, content);
				count++;
			}
		}
	}
	await walk(targetDir);
	return count;
}

/**
 * Rename any file whose basename contains the example slug (`pl-example`)
 * to use the user's slug. WordPress plugins are expected to have a main
 * file named `{slug}.php`, so leaving `pl-example.php` in place would break
 * the convention even if the file's contents were rewritten correctly.
 */
function renameSlugFiles(targetDir, ctx) {
	if (ctx.slug === 'pl-example') return;
	const queue = [targetDir];
	while (queue.length) {
		const dir = queue.shift();
		for (const entry of readdirSync(dir, { withFileTypes: true })) {
			const p = join(dir, entry.name);
			if (entry.isDirectory()) {
				if (SKIP_DIRS.has(entry.name)) continue;
				queue.push(p);
				continue;
			}
			if (!entry.isFile()) continue;
			if (!entry.name.includes('pl-example')) continue;
			const renamed = entry.name.split('pl-example').join(ctx.slug);
			renameSync(p, join(dir, renamed));
		}
	}
}

function stripKitMetaComments(targetDir) {
	for (const f of ['CLAUDE.md', 'AGENTS.md']) {
		const p = join(targetDir, f);
		if (!existsSync(p)) continue;
		const content = readFileSync(p, 'utf8');
		writeFileSync(p, content.replace(/<!--[\s\S]*?-->\s*/g, ''));
	}
}

function writeMinimalReadme(targetDir, ctx) {
	const lines = [`# ${ctx.pluginName}`, ''];
	if (ctx.description) {
		lines.push(ctx.description, '');
	}
	lines.push(
		'## Requirements',
		'',
		`- WordPress ${ctx.wpVersion}+`,
		`- PHP ${ctx.phpVersion}+`,
		'',
	);
	writeFileSync(join(targetDir, 'README.md'), lines.join('\n'));
}

function initGit(targetDir, slug) {
	try {
		execFileSync('git', ['init', '-q'], { cwd: targetDir, stdio: 'ignore' });
		execFileSync('git', ['add', '-A'], { cwd: targetDir, stdio: 'ignore' });
		execFileSync('git', [
			'-c', 'user.email=scaffold@local',
			'-c', 'user.name=scaffold',
			'commit', '-q', '-m', `init: scaffold ${slug} from wp-agentic-kit`,
		], { cwd: targetDir, stdio: 'ignore' });
		execFileSync('git', ['tag', 'scaffold'], { cwd: targetDir, stdio: 'ignore' });
		return true;
	} catch {
		return false;
	}
}

async function runShellJob(name, slug, script, spin, label) {
	// Run a shell script async while a spinner animates. Captures stdout +
	// stderr to /tmp/setup-${name}-${slug}.log so the user can read the
	// full output on failure.
	const logPath = `/tmp/setup-${name}-${slug}.log`;
	spin.start(label);
	const result = await spawnLogged('sh', ['-c', script], process.cwd(), logPath);
	if (result.ok) {
		spin.stop(`${label} — done`);
		return { name, ok: true, logPath };
	}
	spin.stop(`${label} — failed (see ${logPath})`);
	return { name, ok: false, logPath };
}

const WP_DEVDOCS_SCRIPT = `
# wp-core first — required so theme-json's preset_ref classification works
# (soft-degrades to schema-only otherwise, per wp-devdocs-mcp docs).
npx -y -p wp-devdocs-mcp wp-hooks quick-add wp-core --no-index 2>/dev/null || true
npx -y -p wp-devdocs-mcp wp-hooks quick-add theme-json --no-index 2>/dev/null || true
npx -y -p wp-devdocs-mcp wp-hooks source:add \\
	--name=wp-ai-client \\
	--type=github-public \\
	--repo=https://github.com/WordPress/wp-ai-client \\
	--branch=trunk \\
	--content-type=source \\
	--no-index 2>/dev/null || true
npx -y -p wp-devdocs-mcp wp-hooks source:add \\
	--name=abilities-api \\
	--type=github-public \\
	--repo=https://github.com/WordPress/abilities-api \\
	--branch=trunk \\
	--content-type=source \\
	--no-index 2>/dev/null || true
npx -y -p wp-devdocs-mcp wp-hooks index
echo "wp-devdocs ready."
`;

const WP_BLOCKMARKUP_SCRIPT = `
npx -y -p wp-blockmarkup-mcp wp-blocks source:add \\
	--name=gutenberg-core \\
	--type=github-public \\
	--repo=https://github.com/WordPress/gutenberg \\
	--subfolder=packages/block-library/src \\
	--branch=trunk \\
	--no-index 2>/dev/null || true
npx -y -p wp-blockmarkup-mcp wp-blocks index
echo "wp-blockmarkup ready."
`;

function agentSkillsScript(targetDir) {
	// Pull WordPress/agent-skills (trunk) into .claude/skills/, preserving any
	// skill dir that already exists in the scaffold (e.g. the kit's own
	// wordpress-development).
	const dest = join(targetDir, '.claude', 'skills').replace(/'/g, `'\\''`);
	return `
set -e
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
git clone --quiet --depth 1 --branch trunk \\
	https://github.com/WordPress/agent-skills.git "$tmpdir"
mkdir -p '${dest}'
added=0
skipped=0
for src in "$tmpdir/skills/"*/; do
	[ -d "$src" ] || continue
	name=$(basename "$src")
	if [ -e '${dest}'"/$name" ]; then
		echo "skip $name (already in scaffold)"
		skipped=$((skipped+1))
		continue
	fi
	cp -R "$src" '${dest}'"/$name"
	added=$((added+1))
done
echo "agent-skills ready: $added added, $skipped skipped."
`;
}

async function main() {
	const args = parseArgs(process.argv.slice(2));
	if (args.help) {
		printHelp();
		return;
	}

	intro('wp-agentic-kit');

	if (!args.target) {
		const t = await text({
			message: 'Target directory',
			placeholder: 'my-cool-plugin',
			validate: v => (v && v.trim()) ? undefined : 'Required',
		});
		if (isCancel(t)) bail('Cancelled.');
		args.target = t.trim();
	}

	const targetDir = resolve(process.cwd(), args.target);
	if (existsSync(targetDir) && readdirSync(targetDir).length > 0) {
		bail(`Target '${targetDir}' is not empty.`);
	}

	const pluginName = await text({
		message: 'Plugin name',
		placeholder: 'My Cool Plugin',
		validate: v => (v && v.trim()) ? undefined : 'Required',
	});
	if (isCancel(pluginName)) bail('Cancelled.');

	let vendorPrefix = await text({
		message: 'Vendor prefix (optional)',
		placeholder: "e.g. 'pl', 'acme' — blank to skip",
	});
	if (isCancel(vendorPrefix)) bail('Cancelled.');
	vendorPrefix = (vendorPrefix ?? '').trim();

	let description = await text({
		message: 'One-sentence description (optional)',
		placeholder: 'Leave blank to keep the placeholder',
	});
	if (isCancel(description)) bail('Cancelled.');
	description = (description ?? '').trim();

	let author = await text({
		message: 'Author / vendor name (optional)',
		placeholder: "e.g. 'Pluginslab' — blank to skip",
	});
	if (isCancel(author)) bail('Cancelled.');
	author = (author ?? '').trim();

	const wpVersion = await select({
		message: 'Minimum WordPress version',
		initialValue: '6.7',
		options: [
			{ value: '6.6', label: '6.6' },
			{ value: '6.7', label: '6.7' },
			{ value: '6.8', label: '6.8' },
			{ value: '7.0', label: '7.0' },
		],
	});
	if (isCancel(wpVersion)) bail('Cancelled.');

	const phpVersion = await select({
		message: 'Minimum PHP version',
		initialValue: '8.2',
		options: [
			{ value: '8.0', label: '8.0' },
			{ value: '8.1', label: '8.1' },
			{ value: '8.2', label: '8.2' },
			{ value: '8.3', label: '8.3' },
			{ value: '8.4', label: '8.4' },
		],
	});
	if (isCancel(phpVersion)) bail('Cancelled.');

	const trimmedName = pluginName.trim();
	const identity = deriveIdentity(trimmedName, vendorPrefix);

	note(
		[
			`Plugin name:       ${trimmedName}`,
			`Description:       ${description || '(unchanged placeholder)'}`,
			`Author:            ${author || '(unchanged placeholder)'}`,
			`WordPress:         ${wpVersion}+`,
			`PHP:               ${phpVersion}+`,
			`Slug:              ${identity.slug}`,
			`Namespace:         ${identity.namespace}`,
			`Constant prefix:   ${identity.constPrefix}`,
			`Function prefix:   ${identity.fnPrefix}`,
		].join('\n'),
		'Identity'
	);

	const proceed = await confirm({
		message: `Scaffold into ${targetDir}?`,
		initialValue: true,
	});
	if (isCancel(proceed) || !proceed) bail('Aborted.');

	mkdirSync(targetDir, { recursive: true });

	const spin = spinner();
	spin.start(`Fetching ${REPO_OWNER}/${REPO_NAME}@${args.ref}`);
	try {
		await fetchAndExtract(args.ref, targetDir);
	} catch (err) {
		spin.stop('Fetch failed');
		bail(err.message || String(err));
	}
	spin.stop('Templates fetched');

	for (const rel of REMOVE_AFTER_EXTRACT) {
		const p = join(targetDir, rel);
		if (existsSync(p)) rmSync(p, { recursive: true, force: true });
	}

	spin.start('Applying identity');
	const ctx = {
		...identity,
		pluginName: trimmedName,
		description,
		author,
		wpVersion,
		phpVersion,
	};
	const changed = await substitute(targetDir, ctx);
	renameSlugFiles(targetDir, ctx);
	stripKitMetaComments(targetDir);
	writeMinimalReadme(targetDir, ctx);
	spin.stop(`Rewrote ${changed} file(s)`);

	const installResults = [];

	if (existsSync(join(targetDir, 'composer.json'))) {
		spin.start('Installing PHP dependencies (composer install)');
		const logPath = `/tmp/setup-composer-${identity.slug}.log`;
		const r = await spawnLogged('composer', ['install', '--no-interaction', '--no-progress'], targetDir, logPath);
		if (r.ok) {
			spin.stop('PHP dependencies installed');
			installResults.push({ name: 'composer', ok: true, logPath });
		} else {
			spin.stop(`composer install failed (see ${logPath})`);
			installResults.push({ name: 'composer', ok: false, logPath });
		}
	}

	if (existsSync(join(targetDir, 'package.json'))) {
		spin.start('Installing JS dependencies (npm install)');
		const logPath = `/tmp/setup-npm-${identity.slug}.log`;
		const r = await spawnLogged('npm', ['install', '--silent', '--no-audit', '--no-fund'], targetDir, logPath);
		if (r.ok) {
			spin.stop('JS dependencies installed');
			installResults.push({ name: 'npm', ok: true, logPath });
		} else {
			spin.stop(`npm install failed (see ${logPath})`);
			installResults.push({ name: 'npm', ok: false, logPath });
		}
	}

	const indexingResults = [
		await runShellJob('agent-skills', identity.slug, agentSkillsScript(targetDir), spin, 'Syncing WordPress/agent-skills into .claude/skills/'),
		await runShellJob('wp-devdocs', identity.slug, WP_DEVDOCS_SCRIPT, spin, 'Indexing wp-devdocs sources (wp-core + theme-json + wp-ai-client + abilities-api)'),
		await runShellJob('wp-blockmarkup', identity.slug, WP_BLOCKMARKUP_SCRIPT, spin, 'Indexing wp-blockmarkup (gutenberg-core)'),
	];

	const gitOk = initGit(targetDir, identity.slug);

	const lines = [
		`Scaffolded into ${targetDir}`,
		'',
		'Next:',
		`  cd ${args.target}`,
		'  claude        # start coding with the harness loaded',
	];
	if (gitOk) {
		lines.push('', 'Git initialised with tag `scaffold` on the initial commit.');
	}
	const failures = [
		...installResults.filter(r => !r.ok),
		...indexingResults.filter(r => !r.ok),
	];
	if (failures.length > 0) {
		lines.push('', 'Some steps did not finish cleanly:');
		for (const f of failures) {
			lines.push(`  - ${f.name}${f.logPath ? ` (log: ${f.logPath})` : ''}`);
		}
		lines.push('Inspect the logs and rerun the failing step manually.');
	}
	outro(lines.join('\n'));
}

main().catch(err => {
	cancel(err.message || String(err));
	process.exit(1);
});

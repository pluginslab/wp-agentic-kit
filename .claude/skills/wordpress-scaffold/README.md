# wordpress-scaffold skill

Interview-driven scaffolding for **brand-new** WordPress plugins. Use once per plugin, at greenfield. For adding features to an existing plugin, use [`wordpress-feature`](../wordpress-feature/) instead.

## Maps to the talk's framework

**Delegação.** This is the work you stop doing by hand — naming, headers, bootstrap, security boilerplate — and hand to the agent.

## Invoke

```
/wordpress-scaffold
```

Inside a Claude Code session, in an empty directory or one without an existing plugin main file.

## What you get

Six phases, all interview-driven:

1. **Identity** — name, slug, namespace, prefixes
2. **Constitution** — write `.claude/plans/constitution.md` with allowlists
3. **Feature selection** — Settings page? REST? Blocks? Editor extensions?
4. **Spec + plan** — write the initial-scaffold spec and plan
5. **Generate** — files on disk
6. **Deliver** — next-step commands + archive the initial plan

## What's enforced

- WordPress Coding Standards (PHPCS-ready)
- Full security checklist from @../../references/SECURITY.md
- Modern PHP 8.2+ syntax (constructor promotion, readonly, enums where useful)
- Block API v3 for Gutenberg — see @../../references/BLOCKS.md

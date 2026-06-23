# Contribution plans

Scoped specs produced by `/scope-contribution` are saved here for handoff to `/scaffold-contribution`.

## Naming

Each plan is a single Markdown file:

```txt
.cursor/plans/<YYYY-MM-DD>-<scope>-<kebab-slug>.md
```

Examples:

- `.cursor/plans/2026-06-22-anthropic-resolve-base-url-helper.md`
- `.cursor/plans/2026-06-22-core-vector-store-type-hints.md`

Use the Conventional Commit **scope** from the spec (for example `anthropic`, `core`, `langchain`).

## Workflow

1. **PM** runs `/scope-contribution` → agent writes the filled spec to this folder.
2. **Engineer** runs `/scaffold-contribution` → agent lists plans here, loads the chosen file, and implements against its acceptance criteria.

If multiple plans exist, the scaffold skill lists them (newest first) and asks which to use unless the user names a file or says `latest`.

## Git

Plans are local working artifacts by default. Commit a plan only when you want to share it on a branch or with a teammate.

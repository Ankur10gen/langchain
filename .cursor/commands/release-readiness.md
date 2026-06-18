# Release readiness check

For **maintainers and DevOps** preparing or reviewing a `release(scope): x.y.z` PR. Not for routine feature contributions.

## Model

**Claude Sonnet** — release/deployment risk analysis only.

## When to use

- PR title starts with `release(`
- `pyproject.toml` version bumps in the diff
- Before triggering `.github/workflows/_release.yml`

## Step 1 — Gather context

```bash
git diff --name-only master...HEAD
git log --oneline master...HEAD
```

Identify package path (`libs/partners/<name>/`, `libs/core/`, etc.) and proposed version from `pyproject.toml` / `_version.py`.

## Step 2 — Release checklist

Mark PASS, FAIL, or N/A with a one-line note.

### Version and manifest

- [ ] PR title is `release(scope): x.y.z` (no extra text in title for releases per `pr_lint.yml`)
- [ ] Version bumped consistently in `pyproject.toml` and `_version.py` if applicable
- [ ] `make check_version` passes in the package directory (if target exists)
- [ ] `uv.lock` updated only as part of intentional release prep

### Dependency / deployment risk

- [ ] Runtime dependency pins resolve on **PyPI** (see `.github/workflows/check_release_deps.yml`)
- [ ] Intra-monorepo pins (e.g. `langchain-core>=…`) coordinated with sibling releases in same PR or already published
- [ ] No new undeclared dependencies
- [ ] End-user `pip install <pkg>==x.y.z` would resolve (no unpublished pin to external packages)

### Public API and behavior

- [ ] No unintended breaking changes to exports in `__init__.py`
- [ ] Changelog / release notes prepared if required by team process
- [ ] Integration tests passing for the package (CI secrets required)

### CI and infra

- [ ] `pre_merge_ci.sh --allow-deps --package <path> "release(scope): x.y.z"` passes locally
- [ ] `check_versions.yml` and `check_release_deps.yml` expected to pass on PR
- [ ] Release dropdown in `_release.yml` includes this package (see `AGENTS.md` — adding new partner)

## Step 3 — Run gates

```bash
.cursor/scripts/pre_merge_ci.sh --allow-deps --base master --package <package-path> "release(scope): x.y.z"
```

From package directory, also run:

```bash
make check_version   # if available in Makefile
make test
```

## Step 4 — Produce release readiness report

```markdown
# Release readiness report

**Package:** ...
**Version:** ...
**PR title:** release(scope): x.y.z

## Summary
ready / blocked / needs maintainer review

## Checklist
| Check | Status | Notes |
|-------|--------|-------|
| ... | PASS/FAIL/N/A | ... |

## Dependency / PyPI risk
- ...

## Deployment risk (post-release)
- What breaks if this version ships?
- Rollback plan: publish previous patch if needed (maintainer process)

## CI workflows to watch
- check_release_deps.yml
- check_versions.yml
- integration_tests.yml (if applicable)

## Blockers
1. ...

## Maintainer next steps
1. Merge release PR
2. Trigger `_release.yml` with working-directory and release-version
```

Be explicit: this skill does **not** trigger PyPI publish — it assesses readiness only.

# LangChain Onboarding Kit — Cursor Automations

Skills under `.cursor/skills/` stay the source of truth for workflow steps. **Automations** wrap each skill with a **pinned model** and a one-shot prompt so contributors do not have to switch models manually in chat.

## Why automations + skills

| Problem | Skills alone | With automations |
|---------|--------------|------------------|
| Model selection | Human picks model before `/skill` | `workflow.model` is prefilled |
| Cross-model review | Easy to forget new chat + Sonnet | Separate automation run enforces Sonnet |
| Discoverability | `/` menu in Agent chat | Automations dashboard + webhook run |

Skills are unchanged. Each automation prompt tells the agent to read the matching `SKILL.md` and follow it.

## Workflows (prefill JSON)

| Automation | Skill | Pinned model | Prefill file |
|------------|-------|--------------|--------------|
| LangChain: Scope contribution | `scope-contribution` | GPT-5.5 | `prefill/scope-contribution.json` |
| LangChain: Scaffold contribution | `scaffold-contribution` | Composer | `prefill/scaffold-contribution.json` |
| LangChain: Review before PR | `review-before-pr` | Claude Sonnet | `prefill/review-before-pr.json` |
| LangChain: Release readiness | `release-readiness` | Claude Sonnet | `prefill/release-readiness.json` |
| LangChain: Pre-merge CI (DevOps) | (shell gates) | Claude Sonnet | `prefill/pre-merge-ci.json` |

### Recommended pipeline

```text
Scope (GPT-5.5)  →  Scaffold (Composer)  →  Review (Sonnet)  →  open PR
                                              ↑ new automation run ↑
```

Release PRs: run **Release readiness** instead of **Review before PR**.

## One-time setup (per developer or team)

**Recommended: manual create** (reliable). Prefill via agent MCP is optional and often does not populate the form — see [Troubleshooting](#troubleshooting-prefill-is-empty).

### Option A — Manual create (recommended)

For each workflow in the table above:

1. **Automations → New automation** (or Agents Window → create automation).
2. Copy **name**, **description**, **prompt**, and **model** from the matching `prefill/*.json` file.
3. **Trigger:** Webhook (or any on-demand trigger your build supports).
4. **Repository:** Single repo — `langchain-ai/langchain`, branch `master` (or your fork / branch).
5. **Save.**

Start with **Scope contribution** only; add the rest after you confirm one saves and runs.

### Option B — Agent prefill (may not populate)

Only works when **all** of these are true:

1. You are in the **Agents Window** (not regular editor chat).
2. The agent calls `open_automation` with `prefillWorkflowData`.
3. You **Approve** that tool call (prefill is rejected if you skip or deny approval).
4. The **Glass** automation form is the active view when the call completes (not the empty Automations list).

Ask in Agents Window:

> Open the LangChain scope-contribution automation prefill from `.cursor/automations/prefill/scope-contribution.json`

If the form opens blank, use Option A.

### 2. Adjust git scope

Prefills default to:

```json
"gitConfig": {
  "repo": "langchain-ai/langchain",
  "branch": "master"
}
```

Change **repo** to your fork (`YOUR_USER/langchain`) if you contribute from a fork. Set **branch** to your working branch if needed.

### 3. Confirm model IDs

Prefills use automation model slugs:

| Prefill `model` | UI label (approx.) |
|-----------------|-------------------|
| `gpt-5.5` | GPT-5.5 |
| `composer-2.5` | Composer |
| `claude-4.6-sonnet` | Claude Sonnet |

If the picker shows a different slug after import, select the matching model once and save. Cursor may rename slugs between versions.

### 4. Trigger: webhook (on-demand)

Each prefill uses a **webhook** trigger so you can:

- **Run** from the Automations UI after saving (copy webhook URL or use Run if available)
- Invoke from CI or a script when you add team automation later

For a fully manual flow, you can change the trigger in the editor to whatever your Cursor build supports for on-demand runs.

### 5. Save and name

Keep the prefilled names (`LangChain: …`) so the pipeline handoff messages in each prompt stay accurate.

## Running a workflow

1. Open **Automations** in Cursor.
2. Choose the workflow for your role (e.g. **LangChain: Scaffold contribution**).
3. Start a run (webhook / Run button).
4. Provide input in the run prompt when asked (feature idea, package path, PR title).
5. Follow the handoff message to the next automation — **do not** continue the cross-model step in the same run.

Skills (`/scope-contribution`, etc.) still work in Agent chat for ad-hoc use; automations are the **model-enforced** path for the demo and for teams that want consistency.

## Maintenance

When a skill changes:

1. Edit `.cursor/skills/<name>/SKILL.md` (workflow steps, gates, templates).
2. Update only the **handoff / gate references** in the matching `prefill/*.json` prompt if needed — not the full skill text.
3. Re-open the automation in the editor and save if you changed model or git config.

When models change in Cursor, update `workflow.model` in the prefill files and re-import.

## Troubleshooting: prefill is empty

| Symptom | Cause | Fix |
|---------|-------|-----|
| Automations list is empty | JSON files are not saved automations | Create + **Save** in the editor (Option A) |
| New form opens but fields are blank | Prefill only applies to active Glass view; approval may have been skipped | Use Option A — copy from `prefill/*.json` |
| Opened Automations panel yourself first | Prefill was sent to a different Glass tab | Close extra tabs; let agent open the form, or use Option A |

The `prefill/*.json` files are **documentation + copy source**, not auto-imported config.

## File layout

```txt
.cursor/automations/
├── README.md
└── prefill/
    ├── scope-contribution.json
    ├── scaffold-contribution.json
    ├── review-before-pr.json
    ├── release-readiness.json
    └── pre-merge-ci.json
```

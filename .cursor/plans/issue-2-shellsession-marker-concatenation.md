## Contribution scope

_Automated by LangChain: Scope contribution_

### Problem / user story

As a LangChain user who relies on `ShellToolMiddleware` or `ShellSession`, I need shell commands that produce stdout without a trailing newline to complete normally, so common commands such as `echo -n`, `printf`, and `cat` on files without a final newline do not hang until `command_timeout`.

Today `ShellSession.execute()` writes a generated done marker after the command and `_collect_output()` only recognizes the command as complete when a stdout line starts with that marker. If the command output does not end with `\n`, the shell writes the marker immediately after the final output bytes, so the reader sees a line shaped like `hello__LC_SHELL_DONE__... 0\n`. Because the marker no longer starts the line, completion is missed, the command times out, and the shell session is restarted.

### Package / area

- Package: `langchain` (`libs/langchain_v1`)
- Primary implementation: `langchain.agents.middleware.shell_tool.ShellSession`
- Likely test file: `libs/langchain_v1/tests/unit_tests/agents/middleware/implementations/test_shell_tool.py`

### Goals

- Treat the done marker as valid even when it is concatenated to the final stdout chunk.
- Preserve the command output that appears before the marker.
- Do not leak the marker or marker status into returned output.
- Preserve the command's actual exit code, including non-zero exit codes.
- Preserve existing timeout, shell restart, stderr draining, output truncation, and public API behavior.

### Non-goals

- Do not redesign persistent shell lifecycle management.
- Do not change public `ShellSession`, `ShellToolMiddleware`, or execution policy signatures.
- Do not add model-dependent integration coverage for this bug; deterministic unit tests are sufficient.
- Do not change behavior for commands that already end stdout with a trailing newline, except for the bug fix path.

### Proposed implementation

1. Update `_collect_output()` marker detection for stdout chunks.
   - Keep the existing fast path for `data.startswith(marker)`.
   - Add handling for `marker` appearing later in a stdout chunk.
   - When found inline, split the chunk at the marker:
     - the prefix before the marker is user command output and should be included subject to the existing line/byte truncation rules;
     - the marker and status suffix are control data and should not be included in output.
   - Parse the exit status from the text after the marker using the existing `_safe_int()` pattern.
   - Drain remaining stderr exactly as the current marker path does.

2. Be careful with newline-injection alternatives.
   - A naive `echo; echo marker $?` style fix would make the marker start on a fresh line, but it can overwrite `$?` with the status of `echo` and/or add an extra newline to user-visible output.
   - If the implementation chooses marker emission changes instead of inline marker parsing, it must first save the command status, emit any separator without changing that saved value, and avoid adding unexpected output.

3. Keep the change private and localized.
   - No new exported helpers are needed.
   - A small private helper for splitting/parsing marker chunks is acceptable if it keeps `_collect_output()` readable.

### Tests

Add deterministic unit regression coverage in `test_shell_tool.py`.

Recommended cases:

- `ShellSession.execute('echo -n "hello world"', timeout=...)` returns without timing out, with `exit_code == 0`, and output exactly `hello world`.
- `ShellSession.execute('printf "no newline here"', timeout=...)` returns without timing out and output exactly `no newline here`.
- A `cat` command on a file whose contents do not end with `\n` returns without timing out and preserves the file content.
- A command such as `printf "failed"; false` returns without timing out, preserves output `failed`, and reports the non-zero exit code from `false`.
- Existing newline-terminated commands, timeout behavior, stderr capture, and truncation tests continue to pass.

Suggested focused command from `libs/langchain_v1`:

```bash
uv run --group test pytest tests/unit_tests/agents/middleware/implementations/test_shell_tool.py
```

### Acceptance criteria

- The reproduction in the issue no longer reports timeouts for no-trailing-newline stdout cases.
- Returned output does not contain `__LC_SHELL_DONE__` or the marker exit status.
- Returned output does not gain an extra trailing newline solely because the marker was handled.
- Non-zero exit codes are still reported correctly when stdout does not end with `\n`.
- No public API signatures are changed.
- The focused unit test file passes.

### Risks / edge cases

- The marker is generated with a UUID, so accidental user-output collisions are unlikely, but marker parsing should still remain scoped to stdout and the exact marker for the current command.
- Truncation accounting should count user output only, not marker control text.
- Commands that exit the shell process itself, such as `exit 1`, should continue to use the existing broken-pipe / process-exit handling path.
- Stderr may arrive around the same time as the stdout marker; keep the existing remaining-stderr drain behavior.

### Handoff to engineer

Implement a localized regression fix in `ShellSession._collect_output()` so that the per-command marker can be recognized when it is glued to the final stdout bytes. Add unit tests for `echo -n`, `printf`, file content without a final newline, and non-zero exit status with inline marker output. Verify with the focused `test_shell_tool.py` test file from `libs/langchain_v1`, and avoid public API or behavior changes outside marker completion detection.

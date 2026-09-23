# Closing a document releases open state and clears diagnostics when required

- Slug: `document-close-cleanup`
- Priority: **P1**
- Subsystem: documents
- Outcome: **not exercised**
- Implementation status: Production mechanism exists. The proposed general property was not implemented or executed in this research.

## Claim and evidence

Closing a document releases open state and clears diagnostics when required.

[src/FsAutoComplete/LspServers/AdaptiveServerState.fs:2395-2470](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/src/FsAutoComplete/LspServers/AdaptiveServerState.fs#L2395-L2470)

Close removes open files, tokens, and text changes, then forces adaptive cleanup. Missing or outside-workspace files clear diagnostics.

## Preconditions and input domain

Open/change/close/reopen sequences for untitled, deleted, workspace, and externally referenced project files.

## Boundary and invariant

URI conversion and path normalization precede cleanup. Workspace membership uses runtime filesystem and project checks.

## Observable result and oracle

Inspect public diagnostics and reopened source. Add lifetime counters for subscriptions and tokens if a supported observation seam exists.

## Test method

Generated server command sequences with real temporary directories. Add a repeated lifecycle test with measured resource counts.

## Reach condition and observation bound

15 seconds after close and after reopen. Require a prior diagnostic publication, then observe the policy-specific clear or retention. These are proposed test deadlines, not product service-level guarantees.

## Fault model and expected failure

Close during typecheck, then reopen with a new version. Failure is stale text or a late publication from the closed lifetime.

## Existing test evidence

[test/FsAutoComplete.Tests.Lsp/Utils/Server.Tests.fs:976-990](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/test/FsAutoComplete.Tests.Lsp/Utils/Server.Tests.fs#L976-L990)

The inspected reopen test asserts that the test Document wrapper supplies a greater version. It does not prove server cache cleanup.

Existing test source is inspection evidence only. No test outcome was observed.

## Open questions and limits

Case-sensitive filesystem behavior and retained diagnostics for project files outside the workspace need OS-specific checks.

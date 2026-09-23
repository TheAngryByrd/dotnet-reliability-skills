# Workspace loading refreshes project options and selects a containing project deterministically

- Slug: `workspace-loading-selection`
- Priority: **P1**
- Subsystem: workspace
- Outcome: **not exercised**
- Implementation status: Production mechanism exists. The proposed general property was not implemented or executed in this research.

## Claim and evidence

Workspace loading refreshes project options and selects a containing project deterministically.

[src/FsAutoComplete/LspServers/AdaptiveServerState.fs:1020-1084](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/src/FsAutoComplete/LspServers/AdaptiveServerState.fs#L1020-L1084)

Production loading emits project notifications, calls IWorkspaceLoader, and tracks assets/generated props. FindFirstProject sorts project filenames and selects a containing project at lines 147-157.

## Preconditions and input domain

Restored projects, multiple projects sharing a file, changed assets/props, removed projects, and both loader/compiler modes.

## Boundary and invariant

AdaptiveWorkspaceChosen separates no selection from selected projects. LoadedProject couples compiler options and language version. Membership is checked at selection.

## Observable result and oracle

Independent expected project membership and compiler references. Observe loading completion and query a symbol that depends on the changed reference.

## Test method

Real-loader Expecto integration plus pure selection permutations. Drive the server workspaceLoad path for production invalidation.

## Reach condition and observation bound

30 seconds after a confirmed fixture change or load request. Require loading-start and the changed reference in compiler-visible options. These are proposed test deadlines, not product service-level guarantees.

## Fault model and expected failure

Malformed project, missing assets, restore failure, and repeated load requests. Expected explicit failure or recoverable incomplete state without unrelated project loss.

## Existing test evidence

[test/FsAutoComplete.Tests.Lsp/SnapshotTests.fs:81-164](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/test/FsAutoComplete.Tests.Lsp/SnapshotTests.fs#L81-L164)

Snapshot tests count loader calls before/after a package change. createProjectA is a test-local adaptive wrapper, not production loadProjects.

Existing test source is inspection evidence only. No test outcome was observed.

## Open questions and limits

Which imported files must trigger reload? Production currently filters tracked props by obj-path logic. Verify actual server notifications and failure recovery.

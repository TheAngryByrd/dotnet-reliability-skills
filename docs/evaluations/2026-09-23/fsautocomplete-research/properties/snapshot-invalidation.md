# Project snapshots invalidate the changed dependency closure

- Slug: `snapshot-invalidation`
- Priority: **P1**
- Subsystem: workspace
- Outcome: **not exercised**
- Implementation status: Production mechanism exists. The proposed general property was not implemented or executed in this research.

## Claim and evidence

Project snapshots invalidate the changed dependency closure.

[src/FsAutoComplete/LspServers/ProjectWorkspace.fs:45-174](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/src/FsAutoComplete/LspServers/ProjectWorkspace.fs#L45-L174)

Adaptive inputs build project snapshots. Disk versions use write timestamps. Memory versions use LastTouched ticks.

## Preconditions and input domain

Restored project DAG with leaf, dependent, and unrelated projects. Changes to memory text, disk text, options, and references.

## Boundary and invariant

Adaptive collection types track dependencies. Timestamp strings do not prove content identity, and DateTime.UtcNow does not guarantee unique stamps.

## Observable result and oracle

Independent graph reachability identifies affected projects. Compare source content and stable identities, not only stamps.

## Test method

Generated DAG fixtures with real snapshot construction and file watchers. Keep graph-model checks separate from actual snapshot checks.

## Reach condition and observation bound

After a registered out-of-date callback, force snapshots within 15 seconds. Require the edited file content to be visible. These are proposed test deadlines, not product service-level guarantees.

## Fault model and expected failure

Rapid writes with identical timestamps, deleted references, and repeated no-op reads. Failure is stale content or unrelated invalidation.

## Existing test evidence

[test/FsAutoComplete.Tests.Lsp/SnapshotTests.fs:195-325](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/test/FsAutoComplete.Tests.Lsp/SnapshotTests.fs#L195-L325)

Tests inspect equality, source version, project identity, references, and stamp changes after disk edits.

Existing test source is inspection evidence only. No test outcome was observed.

## Open questions and limits

What happens when writes share filesystem timestamp resolution? Cycles and loader failure recovery need separate cases.

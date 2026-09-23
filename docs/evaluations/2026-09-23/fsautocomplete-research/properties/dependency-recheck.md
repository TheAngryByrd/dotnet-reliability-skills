# A saved dependency changes diagnostics in dependent files and projects

- Slug: `dependency-recheck`
- Priority: **P0**
- Subsystem: workspace
- Outcome: **not exercised**
- Implementation status: Production mechanism exists. The proposed general property was not implemented or executed in this research.

## Claim and evidence

A saved dependency changes diagnostics in dependent files and projects.

[src/FsAutoComplete/LspServers/AdaptiveServerState.fs:2473-2592](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/src/FsAutoComplete/LspServers/AdaptiveServerState.fs#L2473-L2592)

Save checks the current file, then dependent source files and projects. Joined tokens cancel work when roots or other files change.

## Preconditions and input domain

A restored two-file project and a two-project reference chain. Both compiler modes and supported runtime legs.

## Boundary and invariant

CompilerProjectOption distinguishes compiler modes. Project SourceFiles order supplies the dependent suffix, with Array.findIndex assuming membership.

## Observable result and oracle

Introduce a unique type error, then repair it. Observe matching dependent diagnostics and their later removal using a fresh subscription.

## Test method

Existing Expecto integration fixtures plus generated save sequences. Use real FCS and project loaders.

## Reach condition and observation bound

15 seconds after each accepted save, matching the existing test bound. Subscribe before the save and require a distinct error marker. These are proposed test deadlines, not product service-level guarantees.

## Fault model and expected failure

Overlapping saves, cancellation, deletion, and recovery. Failure is stale dependent diagnostics after a confirmed completed trigger.

## Existing test evidence

[test/FsAutoComplete.Tests.Lsp/DependentFileCheckingTests.fs:28-114](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/test/FsAutoComplete.Tests.Lsp/DependentFileCheckingTests.fs#L28-L114)

Tests cover same-project, repeated same text, and cross-project invalidation. Non-empty assertions cannot identify a particular new failure.

Existing test source is inspection evidence only. No test outcome was observed.

## Open questions and limits

Test valid-to-invalid-to-valid changes and multiple roots. Repeated identical errors and stream skips can hide missing fresh observations.

# Analyzer selection and completion preserve document identity and server progress

- Slug: `analyzer-isolation`
- Priority: **P1**
- Subsystem: analyzers
- Outcome: **not exercised**
- Implementation status: Production mechanism exists. The proposed general property was not implemented or executed in this research.

## Claim and evidence

Analyzer selection and completion preserve document identity and server progress.

[src/FsAutoComplete/LspServers/AdaptiveServerState.fs:578-684](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/src/FsAutoComplete/LspServers/AdaptiveServerState.fs#L578-L684)

Built-in analyzers use configuration exclusions. External analyzer selection checks configured or project package paths before running on typed implementation data.

## Preconditions and input domain

Enabled/disabled analyzers, project-specific paths, exclusions, missing implementation files, and multiple documents.

## Boundary and invariant

CompilerProjectOption selects analyzer option variants. Paths use Uri.TryCreate and runtime IsBaseOf checks, not a sandbox.

## Observable result and oracle

Expected fixture diagnostic code/range/source and version. After a failing analyzer, issue an unrelated request and observe completion.

## Test method

Existing Expecto integration with the OptionAnalyzer assembly. Add a controlled throwing and blocking analyzer fixture.

## Reach condition and observation bound

15 seconds after analysis starts. Require analyzer-entry observation before fault injection. These are proposed test deadlines, not product service-level guarantees.

## Fault model and expected failure

Analyzer throw, cancellation, invalid path, and slow execution. Failure is cross-project diagnostic leakage or blocked unrelated work.

## Existing test evidence

[test/FsAutoComplete.Tests.Lsp/ExtensionsTests.fs:338-388](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/test/FsAutoComplete.Tests.Lsp/ExtensionsTests.fs#L338-L388)

Existing test asserts exact OV001 diagnostic data. Server.Tests lines 744-803 count built-in diagnostic groups after changes.

Existing test source is inspection evidence only. No test outcome was observed.

## Open questions and limits

Loaded analyzers execute trusted code in the server. Do not claim process isolation or termination for uncooperative analyzer code.

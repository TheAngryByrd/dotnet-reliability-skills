# Test discovery and execution preserve identities, filters, and terminal outcomes

- Slug: `test-explorer-results`
- Priority: **P1**
- Subsystem: test-explorer
- Outcome: **not exercised**
- Implementation status: Production mechanism exists. The proposed general property was not implemented or executed in this research.

## Claim and evidence

Test discovery and execution preserve identities, filters, and terminal outcomes.

[src/FsAutoComplete.Core/VSTestWrapper.fs:114-156](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/src/FsAutoComplete.Core/VSTestWrapper.fs#L114-L156)

VSTest callbacks aggregate chunks. Async cancellation calls CancelDiscovery or CancelTestRun. DTO mapping uses project source lookup.

## Preconditions and input domain

Real sample assemblies with pass/fail/skip/exception outcomes, filters, multiple projects, and debug attach.

## Boundary and invariant

TestOutcome is a finite mapping. TestItem stores optional locations, but Some null source paths are possible at the adapter boundary.

## Observable result and oracle

Known fixture identities and outcomes, duplicate counts, progress-to-final reconciliation, and child process termination after cancellation.

## Test method

Existing Expecto VSTest integration and a controlled long-running test assembly. Keep static AST discovery tests separate.

## Reach condition and observation bound

30 seconds after launch or five seconds after confirmed cancellation for a controlled fixture. Require host-start evidence. These are proposed test deadlines, not product service-level guarantees.

## Fault model and expected failure

Host exit, adapter exception, canceled discovery, missing SDK, and callback failure. Expected terminal outcome must not appear as an ordinary complete empty result.

## Existing test evidence

[test/FsAutoComplete.Tests.TestExplorer/TestRunTests.fs:16-128](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/test/FsAutoComplete.Tests.TestExplorer/TestRunTests.fs#L16-L128)

Run tests compare expected outcome sets and verify debug PID callback plus OperationCanceledException. Set comparison can hide duplicates.

Existing test source is inspection evidence only. No test outcome was observed.

## Open questions and limits

Does wrapper cleanup end all host processes? Cancellation callbacks request stopping but do not prove termination or session disposal.

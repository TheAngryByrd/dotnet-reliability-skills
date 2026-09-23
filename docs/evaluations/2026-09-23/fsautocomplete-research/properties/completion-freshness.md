# Completion retries use changed text when the trigger arrives before its change

- Slug: `completion-freshness`
- Priority: **P1**
- Subsystem: semantic
- Outcome: **not exercised**
- Implementation status: Production mechanism exists. The proposed general property was not implemented or executed in this research.

## Claim and evidence

Completion retries use changed text when the trigger arrives before its change.

[src/FsAutoComplete/LspServers/AdaptiveFSharpLspServer.fs:841-934](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/src/FsAutoComplete/LspServers/AdaptiveFSharpLspServer.fs#L841-L934)

The handler checks the trigger character, selects cached or fresh checking, and retries after errors with rereading when needed.

## Preconditions and input domain

Completion before, during, and after a dot insertion. Include deletion, empty source, and stale check results.

## Boundary and invariant

Raw context DTOs are checked at runtime. Cached typecheck results are intentionally permitted in selected branches.

## Observable result and oracle

Fixture-derived labels and edit ranges must match the requested source version. Record retry and document-change observations.

## Test method

Expecto integration with controlled change ordering. Avoid sleep-only scheduling.

## Reach condition and observation bound

15 seconds after releasing the delayed change. Require the trigger to be absent initially and present before successful completion. These are proposed test deadlines, not product service-level guarantees.

## Fault model and expected failure

Delayed typecheck, cancellation, and repeated edits. Failure is stale replacement range or a successful result for the wrong trigger.

## Existing test evidence

[test/FsAutoComplete.Tests.Lsp/CompletionTests.fs:79-140](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/test/FsAutoComplete.Tests.Lsp/CompletionTests.fs#L79-L140)

Existing tests assert module completion ordering and start a text change with Async.StartChild before completion.

Existing test source is inspection evidence only. No test outcome was observed.

## Open questions and limits

What freshness guarantee applies to manually invoked completion? Do not assume every response is from the latest full typecheck.

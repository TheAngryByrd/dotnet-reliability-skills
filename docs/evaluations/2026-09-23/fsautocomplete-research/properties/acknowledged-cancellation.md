# Cancellation terminates the acknowledged wait without invoking pre-canceled work

- Slug: `acknowledged-cancellation`
- Priority: **P0**
- Subsystem: concurrency
- Outcome: **not exercised**
- Implementation status: Production mechanism exists. The proposed general property was not implemented or executed in this research.

## Claim and evidence

Cancellation terminates the acknowledged wait without invoking pre-canceled work.

[src/FsAutoComplete/LspServers/Common.fs:53-90](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/src/FsAutoComplete/LspServers/Common.fs#L53-L90)

A lock arbitrates cancellation against event publication. A registered callback cancels the completion task.

## Preconditions and input domain

Pre-canceled and in-flight notifications, synchronous event handlers, completion/cancel races.

## Boundary and invariant

CancellationToken is a changing runtime fact. TaskCompletionSource preserves terminal completion but does not stop underlying work.

## Observable result and oracle

Observe handler-start count and the Async cancellation continuation separately. A canceled wait does not prove handler termination.

## Test method

Expecto with explicit barriers and continuation capture. Test real helper, not a copied model.

## Reach condition and observation bound

One second after cancellation. For in-flight cancellation, first await the handler-start signal. These are proposed test deadlines, not product service-level guarantees.

## Fault model and expected failure

Cancellation before trigger, during handler execution, and after completion. Failure is handler invocation for pre-canceled input or a stuck wait.

## Existing test evidence

[test/FsAutoComplete.Tests.Lsp/Utils/Server.Tests.fs:21-101](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/test/FsAutoComplete.Tests.Lsp/Utils/Server.Tests.fs#L21-L101)

Existing tests assert no pre-canceled handler and an in-flight cancellation outcome with a start signal.

Existing test source is inspection evidence only. No test outcome was observed.

## Open questions and limits

Add separate resource-release assertions at callers. Do not infer that all F# Async work stops when this wait stops.

# A failed diagnostic send resolves waiters and permits later updates

- Slug: `diagnostic-send-recovery`
- Priority: **P0**
- Subsystem: diagnostics
- Outcome: **not exercised**
- Implementation status: Production mechanism exists. The proposed general property was not implemented or executed in this research.

## Claim and evidence

A failed diagnostic send resolves waiters and permits later updates.

[src/FsAutoComplete/LspServers/Common.fs:149-215](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/src/FsAutoComplete/LspServers/Common.fs#L149-L215)

Send failure replaces the URI agent, faults the current completion, and cancels the old agent token. Replacement starts with empty state.

## Preconditions and input domain

One URI, multiple queued updates, a send callback with controlled failure, and later successful sends.

## Boundary and invariant

Agent lifetime tokens release waiting callers. Dictionary replacement is conditional on the failed agent identity.

## Observable result and oracle

Record accepted commands, acknowledgements, exception identity, and later publications. Every acknowledged call must reach a terminal outcome.

## Test method

Expecto with TaskCompletionSource barriers and injected send callback. Exercise the production DiagnosticCollection.

## Reach condition and observation bound

One second after releasing the failing send. First prove the send began and the second update was queued. These are proposed test deadlines, not product service-level guarantees.

## Fault model and expected failure

Throw before send completion, queue further work, then recover. Expected outcomes are explicit faults or cancellations, followed by successful new work.

## Existing test evidence

[test/FsAutoComplete.Tests.Lsp/Utils/Server.Tests.fs:102-139](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/test/FsAutoComplete.Tests.Lsp/Utils/Server.Tests.fs#L102-L139)

The existing test verifies original exception identity and success of one later call. It does not cover queued waiters or retained diagnostics.

Existing test source is inspection evidence only. No test outcome was observed.

## Open questions and limits

Is loss of other source diagnostics on replacement intended? No durable or exactly-once delivery guarantee is established.

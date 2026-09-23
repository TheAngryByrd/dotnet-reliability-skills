# Older diagnostics cannot replace newer diagnostics from the same source

- Slug: `diagnostic-version-order`
- Priority: **P0**
- Subsystem: diagnostics
- Outcome: **not exercised**
- Implementation status: Production mechanism exists. The proposed general property was not implemented or executed in this research.

## Claim and evidence

Older diagnostics cannot replace newer diagnostics from the same source.

[src/FsAutoComplete/LspServers/Common.fs:94-166](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/src/FsAutoComplete/LspServers/Common.fs#L94-L166)

Each URI has a mailbox. Add ignores versions below the stored version for that diagnostic source. The outgoing version is the maximum across sources.

## Preconditions and input domain

Generate Add, versioned-empty Add, and source Clear commands for several sources and URIs.

## Boundary and invariant

DiagnosticMessage distinguishes Add and Clear. Version remains an integer. Clear deliberately removes the version watermark.

## Observable result and oracle

Compare every publication with an independent map of source to version and diagnostic set. Keep source-specific ordering distinct from global publication version.

## Test method

Expecto with generated state-machine commands, then barrier-controlled overlapping writers.

## Reach condition and observation bound

Await every acknowledged Add within one second in an isolated component test. Require a newer update before injecting an older one. These are proposed test deadlines, not product service-level guarantees.

## Fault model and expected failure

Delayed old publications, empty updates, and Clear/Add races. Failure is stale replacement or completion that never resolves.

## Existing test evidence

[test/FsAutoComplete.Tests.Lsp/Utils/Server.Tests.fs:140-168](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/test/FsAutoComplete.Tests.Lsp/Utils/Server.Tests.fs#L140-L168)

The test body checks versioned-empty ordering. Its scope is narrower than multiple concurrent sources and clear races.

Existing test source is inspection evidence only. No test outcome was observed.

## Open questions and limits

Should Clear reset the watermark? Can a late producer repopulate a closed URI? A maximum outgoing version does not prove all diagnostics share that version.

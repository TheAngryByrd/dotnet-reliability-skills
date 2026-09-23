# Symbol queries return the correct identities and current source ranges

- Slug: `symbol-query-consistency`
- Priority: **P1**
- Subsystem: semantic
- Outcome: **not exercised**
- Implementation status: Production mechanism exists. The proposed general property was not implemented or executed in this research.

## Claim and evidence

Symbol queries return the correct identities and current source ranges.

[src/FsAutoComplete/LspServers/AdaptiveFSharpLspServer.fs:1482-1513](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/src/FsAutoComplete/LspServers/AdaptiveFSharpLspServer.fs#L1482-L1513)

References load source and check results, query workspace symbol uses, then convert FCS ranges to LSP locations. Call hierarchy filters callable uses within bindings.

## Preconditions and input domain

Shadowing, same-name symbols, multiple projects, signatures, include-declaration settings, and line insertions.

## Boundary and invariant

Raw request positions are converted before runtime line lookup. FCS symbol identity provides stronger evidence than textual name matching.

## Observable result and oracle

Marked fixture definitions/uses form an independent expected set. Verify hierarchy edges and lens positions after edits.

## Test method

Generated small programs plus existing Expecto examples. Use real FCS to establish implementation behavior.

## Reach condition and observation bound

15 seconds after a request following document analysis. Require both target and confusable symbol occurrences. These are proposed test deadlines, not product service-level guarantees.

## Fault model and expected failure

Stale source, unreadable file, invalid position, and external symbol. Failure is a wrong identity, wrong range, or unsupported success claim.

## Existing test evidence

[test/FsAutoComplete.Tests.Lsp/FindReferencesTests.fs:39-66](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/test/FsAutoComplete.Tests.Lsp/FindReferencesTests.fs#L39-L66)

Reference test checks count and declaration range. CallHierarchyTests lines 51-99 compare exact incoming items. CodeLensTests lines 66-102 start a newline movement case.

Existing test source is inspection evidence only. No test outcome was observed.

## Open questions and limits

References currently passes fixed flags to SymbolUseWorkspace. Verify IncludeDeclaration=false explicitly before concluding protocol compliance.

# Document changes preserve the latest accepted text and version

- Slug: `document-change-consistency`
- Priority: **P0**
- Subsystem: documents
- Outcome: **not exercised**
- Implementation status: Production mechanism exists. The proposed general property was not implemented or executed in this research.

## Claim and evidence

Document changes preserve the latest accepted text and version.

[src/FsAutoComplete/LspServers/AdaptiveServerState.fs:1120-1178](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/src/FsAutoComplete/LspServers/AdaptiveServerState.fs#L1120-L1178)

Changes are sorted by document version, then folded over the open buffer. Full changes replace text. Range failures retain the prior buffer.

## Preconditions and input domain

An open document and strictly increasing LSP versions. Generate valid UTF-16 ranges, LF/CRLF, empty files, and sequences of full and incremental changes.

## Boundary and invariant

Version and range DTOs are primitives. VolatileFile records preserve coexisting source and version, but constructors do not establish monotonicity.

## Observable result and oracle

Compare each resulting buffer and version with an independent string-splice model. Query a semantic marker after every change.

## Test method

Generated command sequences against the real in-process server. Use plain offset arithmetic for the model.

## Reach condition and observation bound

After the change acknowledgement, observe the marker within 15 seconds. Require both the edit receipt and the new marker. These are proposed test deadlines, not product service-level guarantees.

## Fault model and expected failure

Invalid ranges, duplicate versions, and reordered notifications are separate negative cases. Expected failure policy for these inputs needs agreement.

## Existing test evidence

[test/FsAutoComplete.Tests.Lsp/CompletionTests.fs:108-140](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/test/FsAutoComplete.Tests.Lsp/CompletionTests.fs#L108-L140)

The inspected completion test starts a change concurrently with completion. It does not compare arbitrary edit sequences with an independent model.

Existing test source is inspection evidence only. No test outcome was observed.

## Open questions and limits

Are duplicate and older changes rejected, ignored, or reapplied? Sorting alone does not establish this policy.

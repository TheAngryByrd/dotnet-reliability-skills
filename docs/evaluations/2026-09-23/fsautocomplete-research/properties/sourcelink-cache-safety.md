# SourceLink cache paths stay contained and incomplete downloads are not reused

- Slug: `sourcelink-cache-safety`
- Priority: **P0**
- Subsystem: external-navigation
- Outcome: **not exercised**
- Implementation status: Production mechanism exists. The proposed general property was not implemented or executed in this research.

## Claim and evidence

SourceLink cache paths stay contained and incomplete downloads are not reused.

[src/FsAutoComplete.Core/Sourcelink.fs:185-282](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/src/FsAutoComplete.Core/Sourcelink.fs#L185-L282)

SourceLink mappings come from PDB JSON. Download paths combine temp root, document hash, and a mapped fragment. Existing files are reused.

## Preconditions and input domain

Controlled PDB mappings, exact/wildcard paths, traversal segments, rooted paths, interrupted downloads, and same-path retries.

## Boundary and invariant

UMX path tags distinguish roles but allow direct tagging. Trimming a leading slash does not prove canonical containment. File existence is the visible cache gate.

## Observable result and oracle

Canonical path containment and byte equality against a known source/hash. Observe actual writes and successful retry after an interrupted stream.

## Test method

Real temporary filesystem and local HTTP server with controlled streaming. Use generated path cases through the production fetch entry point.

## Reach condition and observation bound

10 seconds after releasing a local response or injected disconnect. Require actual first bytes written before interrupting. These are proposed test deadlines, not product service-level guarantees.

## Fault model and expected failure

Malformed mapping, partial response, cached corruption, or path escape. Expected behavior is explicit failure without reuse or out-of-root writes.

## Existing test evidence

[test/FsAutoComplete.Tests.Lsp/GoToTests.fs:58-86](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/test/FsAutoComplete.Tests.Lsp/GoToTests.fs#L58-L86)

The inspected external go-to test asserts generated .cs location only. It does not establish SourceLink cache containment or download integrity.

Existing test source is inspection evidence only. No test outcome was observed.

## Open questions and limits

This is a proposed hardening contract. Source inspection raises specific concerns but no exploit or runtime violation was executed.

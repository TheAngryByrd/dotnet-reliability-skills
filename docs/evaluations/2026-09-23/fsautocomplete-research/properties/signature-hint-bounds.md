# Signature and inlay hints reference valid source positions and parameters

- Slug: `signature-hint-bounds`
- Priority: **P2**
- Subsystem: semantic
- Outcome: **not exercised**
- Implementation status: Production mechanism exists. The proposed general property was not implemented or executed in this research.

## Claim and evidence

Signature and inlay hints reference valid source positions and parameters.

[src/FsAutoComplete.Core/SignatureHelp.fs:80-145](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/src/FsAutoComplete.Core/SignatureHelp.fs#L80-L145)

Signature help derives argument indices from parsed application ranges and curried groups. InlayHints creates range-bound Hint records and optional insertions.

## Preconditions and input domain

Curried functions, pipelines, tuple groups, nested patterns, signature files, and long Unicode names.

## Boundary and invariant

Hint records preserve position and text together, but do not prove containment. Runtime AST guards restrict applicable branches.

## Observable result and oracle

Check ActiveParameter against returned parameters, exact fixture labels, and all hint/edit positions against source offsets.

## Test method

Generated syntax examples through real FCS and server. Use pure tests for truncation.

## Reach condition and observation bound

15 seconds per semantic request after document analysis. Require a known function application or hinted binding. These are proposed test deadlines, not product service-level guarantees.

## Fault model and expected failure

Malformed source and out-of-range caret. Expected response is no hint or a bounded valid hint, not an indexing exception.

## Existing test evidence

[test/FsAutoComplete.Tests.Lsp/SignatureHelpTests.fs:55-90](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/test/FsAutoComplete.Tests.Lsp/SignatureHelpTests.fs#L55-L90)

Signature tests check the second parameter and both curried parameters. InlayHintTests lines 20-54 compare arrays but reuse production truncated.

Existing test source is inspection evidence only. No test outcome was observed.

## Open questions and limits

Use an independent truncation oracle. The existing helper can share a defect with production truncation.

# Semantic token encoding preserves ordered positions without unsigned underflow

- Slug: `semantic-token-encoding`
- Priority: **P1**
- Subsystem: protocol
- Outcome: **not exercised**
- Implementation status: Production mechanism exists. The proposed general property was not implemented or executed in this research.

## Claim and evidence

Semantic token encoding preserves ordered positions without unsigned underflow.

[src/FsAutoComplete/LspHelpers.fs:1194-1245](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/src/FsAutoComplete/LspHelpers.fs#L1194-L1245)

Encoding emits five unsigned values per token. Multiline or inverted lengths become zero.

## Preconditions and input domain

Sorted token ranges, repeated lines, modifier combinations, empty input, and explicitly invalid ranges.

## Boundary and invariant

Raw uint32 Range permits invalid ordering. Length guards do not establish ordering between successive tokens.

## Observable result and oracle

Decode with independent signed arithmetic and compare positions, token types, flags, and allowed length policy.

## Test method

Pure Expecto property tests. Generate ordered ranges directly and preserve order during shrinking.

## Reach condition and observation bound

Immediate result. Include at least two tokens to exercise relative deltas. These are proposed test deadlines, not product service-level guarantees.

## Fault model and expected failure

Unsorted tokens, multiline ranges, and reversed columns. Failure is huge wrapped values or corrupted subsequent positions.

## Existing test evidence

[test/FsAutoComplete.Tests.Lsp/LspHelpersTests.fs:35-81](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/test/FsAutoComplete.Tests.Lsp/LspHelpersTests.fs#L35-L81)

Existing tests check empty input, exact encoding, and zero lengths for multiline and inverted ranges.

Existing test source is inspection evidence only. No test outcome was observed.

## Open questions and limits

Is sorting a caller precondition? Trace all producers before demanding rejection of unsorted arrays.

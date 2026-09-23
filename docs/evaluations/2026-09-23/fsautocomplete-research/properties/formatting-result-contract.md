# Only complete successful formatter responses produce edits

- Slug: `formatting-result-contract`
- Priority: **P1**
- Subsystem: formatting
- Outcome: **not exercised**
- Implementation status: Production mechanism exists. The proposed general property was not implemented or executed in this research.

## Claim and evidence

Only complete successful formatter responses produce edits.

[src/FsAutoComplete.Core/Commands.fs:451-516](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/src/FsAutoComplete.Core/Commands.fs#L451-L516)

Formatted document responses require content. Selections require both content and range. Other response codes map to a discriminated union.

## Preconditions and input domain

Every Fantomas response code with present/missing content and selection range. Include cancellation and unknown numeric codes.

## Boundary and invariant

FormatDocumentResponse preserves success-specific data. Conversion from the wire integer is checked by exhaustive handling with a fallback.

## Observable result and oracle

Table-driven expected response union and LSP edit/no-edit behavior. Apply successful edits and compare exact source.

## Test method

Expecto component tests using existing injected formatting functions, plus one real Fantomas integration fixture.

## Reach condition and observation bound

One second after injected response completion. For integration, 15 seconds after the daemon request begins. These are proposed test deadlines, not product service-level guarantees.

## Fault model and expected failure

Daemon exception, cancellation, missing tool, and malformed success. Expected error or no edit must preserve the document.

## Existing test evidence

[test/FsAutoComplete.Tests.Lsp/ExtensionsTests.fs:271-335](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/test/FsAutoComplete.Tests.Lsp/ExtensionsTests.fs#L271-L335)

Existing integration restores a tool and checks the whole-document edit against an expected file. It does not cover the full response table.

Existing test source is inspection evidence only. No test outcome was observed.

## Open questions and limits

Confirm selection range units and behavior for edits made while formatting runs. Real daemon termination needs separate testing.

# Configuration updates preserve the chosen omission policy and invalidate dependent state

- Slug: `configuration-transition`
- Priority: **P1**
- Subsystem: configuration
- Outcome: **not exercised**
- Implementation status: Production mechanism exists. The proposed general property was not implemented or executed in this research.

## Claim and evidence

Configuration updates preserve the chosen omission policy and invalidate dependent state.

[src/FsAutoComplete/LspHelpers.fs:1049-1087](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/src/FsAutoComplete/LspHelpers.fs#L1049-L1087)

WorkspaceDidChangeConfiguration deserializes FSharpConfigRequest, calls AddDto, and replaces adaptive config. Invalid regex patterns are logged and dropped.

## Preconditions and input domain

Partial DTOs, explicit values, omitted fields, invalid regexes, FSI argument changes, analyzer toggles, and repeated identical configuration.

## Boundary and invariant

FSharpConfig holds Regex values after parsing, preserving regex syntax. Raw integers and strings retain no range guarantee. DTO conversion precedes state assignment.

## Observable result and oracle

Independent field-level merge/default table and semantic marker affected by the changed setting. Compare unchanged fields separately.

## Test method

Pure conversion tests plus stateful Expecto server sequences. Use fresh diagnostics subscriptions and explicit input versions.

## Reach condition and observation bound

15 seconds after configuration acceptance and affected document reanalysis. Require a diagnostic before changing its controlling setting. These are proposed test deadlines, not product service-level guarantees.

## Fault model and expected failure

Malformed DTO, invalid regex, negative numeric settings, and concurrent requests. Expected rejection/omission behavior must be explicit before asserting it.

## Existing test evidence

[test/FsAutoComplete.Tests.Lsp/ScriptTests.fs:62-98](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/test/FsAutoComplete.Tests.Lsp/ScriptTests.fs#L62-L98)

Script eviction test changes FSI arguments and waits for diagnostics, but its enclosing ptestList is pending. It is not active executed coverage.

Existing test source is inspection evidence only. No test outcome was observed.

## Open questions and limits

AddDto's comment says omitted values revert to defaults, while inspected fields retain prior values. Treat this as a contract conflict, not a measured defect.

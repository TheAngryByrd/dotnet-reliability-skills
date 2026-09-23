# Applicable code fixes produce valid localized edits and remove their target diagnostic

- Slug: `code-fix-correctness`
- Priority: **P1**
- Subsystem: edits
- Outcome: **not exercised**
- Implementation status: Production mechanism exists. The proposed general property was not implemented or executed in this research.

## Claim and evidence

Applicable code fixes produce valid localized edits and remove their target diagnostic.

[src/FsAutoComplete/CodeFixes/GenerateAnonRecordStub.fs:21-110](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/src/FsAutoComplete/CodeFixes/GenerateAnonRecordStub.fs#L21-L110)

Anonymous record fixes parse compiler messages, confirm diagnostic code and AST location, then compute missing fields. Fix wrappers attach document versions.

## Preconditions and input domain

Single/multiple missing fields, nested anonymous records, quoted field names, unsupported messages, and different language versions.

## Boundary and invariant

Fix is a record of raw edits. Non-overlap and language validity are not encoded. Diagnostic parsing uses option and falls back to no fix.

## Observable result and oracle

Independently apply edits and compare expected text. Recheck source and require the target diagnostic to disappear without unexpected new errors.

## Test method

Keep Expecto code-fix fixtures. Add generated syntax families and isolated source mutants for diagnostic gates and insertion boundaries.

## Reach condition and observation bound

15 seconds after applying the returned edit to the same document version. Require the target diagnostic before requesting the fix. These are proposed test deadlines, not product service-level guarantees.

## Fault model and expected failure

Compiler message changes, stale ranges, and missing AST nodes. Expected failure is no applicable fix or an explicit error, without destructive edits.

## Existing test evidence

[test/FsAutoComplete.Tests.Lsp/CodeFixTests/GenerateAnonRecordStubTests.fs:9-39](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/test/FsAutoComplete.Tests.Lsp/CodeFixTests/GenerateAnonRecordStubTests.fs#L9-L39)

Three inspected tests provide expected final text for one, multiple, and empty-record cases. Other fix modules remain only sampled.

Existing test source is inspection evidence only. No test outcome was observed.

## Open questions and limits

Compiler localization and punctuation can affect regex parsing. Full coverage of all code-fix modules remains incomplete.

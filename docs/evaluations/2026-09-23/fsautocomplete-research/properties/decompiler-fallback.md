# External navigation selects an existing implementation assembly and valid location

- Slug: `decompiler-fallback`
- Priority: **P2**
- Subsystem: external-navigation
- Outcome: **not exercised**
- Implementation status: Production mechanism exists. The proposed general property was not implemented or executed in this research.

## Claim and evidence

External navigation selects an existing implementation assembly and valid location.

[src/FsAutoComplete.Core/Decompiler.fs:62-128](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/src/FsAutoComplete.Core/Decompiler.fs#L62-L128)

Resolution tries the last ref-to-lib path substitution, then targeting-pack metadata. Candidates must exist.

## Preconditions and input domain

NuGet layouts, pack layouts, malformed XML, absent implementation files, repeated ref segments, and overloaded external symbols.

## Boundary and invariant

Resolver returns option<FilePath-as-string>. Existence is a runtime check. Metadata compatibility is not proved by existence.

## Observable result and oracle

Independent fixture paths and known method body markers. Returned navigation ranges must lie within the generated file.

## Test method

Temporary filesystem examples plus real assembly/PDB integration for decompilation and symbol location.

## Reach condition and observation bound

15 seconds after navigation request. Require the fixture to contain distinguishable reference and implementation assemblies. These are proposed test deadlines, not product service-level guarantees.

## Fault model and expected failure

Missing files, malformed metadata, and assembly resolution failure. Expected fallback or explicit error must leave later requests usable.

## Existing test evidence

[test/FsAutoComplete.Tests.Lsp/DecompilerTests.fs:54-97](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/test/FsAutoComplete.Tests.Lsp/DecompilerTests.fs#L54-L97)

Tests create ref/lib files and compare returned paths. The go-to test checks a .cs filename, not actual method bodies.

Existing test source is inspection evidence only. No test outcome was observed.

## Open questions and limits

Test same-name incompatible assemblies and overload matching. Path tests alone do not prove decompiled symbol correctness.

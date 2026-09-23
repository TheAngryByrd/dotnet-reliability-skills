# Project edits preserve compile order and unrelated project content

- Slug: `project-edit-integrity`
- Priority: **P0**
- Subsystem: project-commands
- Outcome: **not exercised**
- Implementation status: Production mechanism exists. The proposed general property was not implemented or executed in this research.

## Claim and evidence

Project edits preserve compile order and unrelated project content.

[src/FsAutoComplete.Core/FsprojEdit.fs:73-206](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/src/FsAutoComplete.Core/FsprojEdit.fs#L73-L206)

XML edits move sibling Compile nodes, reject duplicate adds, and save directly to the project path.

## Preconditions and input domain

Project XML with comments, conditions, mixed item kinds, escaped filenames, existing/missing anchors, and LF/CRLF.

## Boundary and invariant

Paths are raw strings inserted into XPath. Duplicate checks normalize separators only. There is no transaction type or atomic write visible.

## Observable result and oracle

Independent ordered Compile model plus XML comparison excluding the intended operation. On rejected input, compare original bytes.

## Test method

Generated operation sequences against temporary real files. Add controlled filesystem failure cases.

## Reach condition and observation bound

Immediate return for local operations. Require a saved baseline and parseable input before each operation. These are proposed test deadlines, not product service-level guarantees.

## Fault model and expected failure

Invalid XPath characters, missing anchor, duplicate paths, write denial, or interrupted save. Expected failure must not silently corrupt the project.

## Existing test evidence

[test/FsAutoComplete.Tests.Lsp/FsProjEditorTests.fs:78-120](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/test/FsAutoComplete.Tests.Lsp/FsProjEditorTests.fs#L78-L120)

Inspected tests assert move order, top boundary, and repeated moves. Broader write-failure behavior is not established.

Existing test source is inspection evidence only. No test outcome was observed.

## Open questions and limits

Atomic persistence is a proposed stronger contract, not an established implementation guarantee. Cross-process concurrent edits need an explicit policy.

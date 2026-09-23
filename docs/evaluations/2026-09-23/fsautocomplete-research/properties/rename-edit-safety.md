# Rename edits change only the selected symbol in readable documents

- Slug: `rename-edit-safety`
- Priority: **P0**
- Subsystem: edits
- Outcome: **not exercised**
- Implementation status: Production mechanism exists. The proposed general property was not implemented or executed in this research.

## Claim and evidence

Rename edits change only the selected symbol in readable documents.

[src/FsAutoComplete/LspServers/AdaptiveFSharpLspServer.fs:1328-1405](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/src/FsAutoComplete/LspServers/AdaptiveFSharpLspServer.fs#L1328-L1405)

Rename checks the proposed name and symbol eligibility. It omits unreadable files, filters accessor keywords, and deduplicates starts.

## Preconditions and input domain

Workspace with definitions, shadowing, property accessors, quoted identifiers, and multiple project references.

## Boundary and invariant

New name returns Result before edit construction. Workspace edits carry document versions where client capabilities support them.

## Observable result and oracle

Use fixture-marked expected occurrences. Apply edits independently, assert no overlap, and recheck changed programs against expected symbol bindings.

## Test method

Generated small F# programs with real server rename. Preserve exact fixture assertions for difficult compiler cases.

## Reach condition and observation bound

15 seconds after rename request. Require the selected symbol and at least one separate use before asserting completeness. These are proposed test deadlines, not product service-level guarantees.

## Fault model and expected failure

Concurrent edits and unreadable external sources. Failure is wrong-symbol replacement, overlapping edits, or missing eligible local use.

## Existing test evidence

[test/FsAutoComplete.Tests.Lsp/RenameTests.fs:59-133](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/test/FsAutoComplete.Tests.Lsp/RenameTests.fs#L59-L133)

Existing same-project tests assert two document changes and specific ranges. They do not independently prove all unaffected text remains unchanged.

Existing test source is inspection evidence only. No test outcome was observed.

## Open questions and limits

An edit can be built after source changes. Verify snapshot/version coherence and client capability fallback.

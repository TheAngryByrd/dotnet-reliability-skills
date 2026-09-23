# Document URI conversion preserves identity across working-directory changes

- Slug: `uri-identity`
- Priority: **P1**
- Subsystem: text
- Outcome: **not exercised**
- Implementation status: Production mechanism exists. The proposed general property was not implemented or executed in this research.

## Claim and evidence

Document URI conversion preserves identity across working-directory changes.

[src/FsAutoComplete.Core/Utils.fs:668-695](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/src/FsAutoComplete.Core/Utils.fs#L668-L695)

FileUriToLocalPath normalizes Windows drive casing. Untitled URIs receive .fsx and a base under AppContext.BaseDirectory.

## Preconditions and input domain

File and untitled URIs, percent encoding, spaces, Unicode, drive letters, short paths, and current-directory changes.

## Boundary and invariant

LocalPath is a measure tag with unrestricted tagging. It does not prove a canonical absolute path or valid URI.

## Observable result and oracle

Use canonical independently constructed expected paths. Round-trip only where the documented URI mapping is invertible.

## Test method

Pure generated path cases on Windows and Linux, plus server open/navigation scenarios.

## Reach condition and observation bound

Immediate conversion, then 15 seconds for server navigation. Change the working directory between open and query. These are proposed test deadlines, not product service-level guarantees.

## Fault model and expected failure

Malformed URI and very short local paths. Expected rejection policy must be explicit and must not merge distinct documents.

## Existing test evidence

[test/FsAutoComplete.Tests.Lsp/CoreUtilsTests.fs:129-137](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/test/FsAutoComplete.Tests.Lsp/CoreUtilsTests.fs#L129-L137)

CoreUtilsTests checks ordinary Untitled-prefixed file resolution against the current directory. This differs from an actual untitled: URI.

Existing test source is inspection evidence only. No test outcome was observed.

## Open questions and limits

Uri construction and the three-character drive slice can throw. Define supported minimum path forms and error conversion at request boundaries.

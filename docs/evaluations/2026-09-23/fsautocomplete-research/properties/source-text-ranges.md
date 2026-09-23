# Valid UTF-16 text ranges preserve all text outside the replaced range

- Slug: `source-text-ranges`
- Priority: **P1**
- Subsystem: text
- Outcome: **not exercised**
- Implementation status: Production mechanism exists. The proposed general property was not implemented or executed in this research.

## Claim and evidence

Valid UTF-16 text ranges preserve all text outside the replaced range.

[src/FsAutoComplete.Core/FileSystem.fs:93-103](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/src/FsAutoComplete.Core/FileSystem.fs#L93-L103)

ToRoslynTextSpan converts FCS lines and columns. ModifyText constructs TextChange and calls Roslyn WithChanges at lines 342-345.

## Preconditions and input domain

Generate valid ranges from offsets into strings with surrogate pairs, empty lines, trailing newline, LF, and CRLF.

## Boundary and invariant

IFSACSourceText exposes Result but raw Range remains constructible. ToRoslynTextSpan clamps selected line indices and can still throw.

## Observable result and oracle

An independent UTF-16 offset model computes prefix + replacement + suffix. Check extraction and final text.

## Test method

Expecto plus FsCheck or Hedgehog generators with validity-preserving shrinking.

## Reach condition and observation bound

Immediate pure result. Require the generated range to select a known marker before replacement. These are proposed test deadlines, not product service-level guarantees.

## Fault model and expected failure

Out-of-range and reversed ranges are separate negative inputs. The Result return type does not itself prevent constructor exceptions.

## Existing test evidence

No direct test body is claimed.

No direct ModifyText tests were found in the inspected search. TextEdit test utilities are not automatically tests of this production implementation.

Existing test source is inspection evidence only. No test outcome was observed.

## Open questions and limits

Specify invalid-range behavior at the public boundary before broadening the valid-range property.

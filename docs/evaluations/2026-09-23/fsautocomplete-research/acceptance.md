# Research scope acceptance

Source revision: `85886b187b87834e0fe0a410cb13332d7f9757ca`.
Applied skill revision: `0e4e2df532eaff581ac2d931a45bcf3f1294a770`.

## Decision

Accepted as a repository-wide reliability catalog at subsystem-contract depth.
The [coverage matrix](coverage.md) records detailed branches that remain partially inspected.
This acceptance does not establish exhaustive function coverage or runtime correctness.

The [earlier script-options report](../fsautocomplete.md) fails this scope check.
It investigates one behavior and cannot account for the repository's major subsystems, regardless of its passing test results.

## Independent inventory check

The parent inspected the solution, production project compile items, server request interfaces, and representative state/effect boundaries independently of the evaluator.
The solution contains eight top-level projects. The source tree contains 44 F#/C# project files, including fixtures.
All eight top-level projects are accounted for in [system.md](system.md).

The independent inventory included protocol/process lifetime, document state, source ranges and URI identity, project loading, compiler/cache state, diagnostics, cancellation, and configuration.
It also included editor queries and edits, analyzers, formatting, external source retrieval, project commands, test discovery/execution, logging, and build support.
These areas map to the 19 groups and 31 property records in the final catalog.

## Evidence checks

- Sampled production and test bodies for document changes, diagnostic recovery, compiler/cache behavior, project selection, configuration, external source retrieval, and subprocess ownership.
- Checked that records distinguish existing test intent from observed test outcomes.
- Verified 116 pinned source citation occurrences against local file paths and line bounds at the exact target revision.
- Verified 63 local artifact links before adding this acceptance document.
- Confirmed the target checkout remained clean.

Citation validation establishes that referenced locations exist. The sampled body review checks substantive attribution. Neither is a full implementation audit.

## Corrections required before acceptance

The first catalog draft lacked explicit project-loading and configuration-transition properties.
These were required before acceptance, along with a compiler/script-cache record that accounts for invalidation behavior.

The subprocess record initially deferred inspection of an available helper.
It now includes `WaitForExitAsync` source evidence and distinguishes wait cancellation from child-process termination.

These corrections apply the scope check to the result. A subsystem name alone does not satisfy the check.

## Separate execution verdict

No new FsAutoComplete build, test, mutation, or fault experiment ran during this research rerun.
All 31 property outcomes are **not exercised**.
The prior focused test results remain associated with the prior report and do not establish the new catalog's properties.

# Research evaluation

Date: 2026-09-23. Source revision: `85886b187b87834e0fe0a410cb13332d7f9757ca`.
Skill revision: `0e4e2df532eaff581ac2d931a45bcf3f1294a770`.

## Result

The requested repository-wide catalog contains 31 properties across 19 major areas.
The major areas have source-backed contract inspection and catalog entries.
Detailed implementation research remains incomplete for the variants listed in coverage.md.
This is a reliability research catalog, not a defect report or exhaustive function-level audit.

## Execution status

| Activity | Status | Evidence and limit |
| --- | --- | --- |
| Source/project/test-body inspection | completed | Pinned citations in every property record and coverage.md. |
| Source revision and dirty-state check | completed | Expected SHA confirmed. git status --short was empty before and after inspection. |
| Environment inventory | completed | SDK 10.0.401, host 10.0.12, Windows win-x64 observed with dotnet --info. |
| Restore/build | not exercised | Research-only assignment. |
| Existing tests | not exercised | Source inspected. No pass count or run result is claimed. |
| New properties | not exercised | No tests or dependencies were added. |
| Fault injection, mutation, performance | not exercised | Proposed methods only. |
| External service health | not exercised | Historical source comments are not current availability evidence. |

All 31 property outcomes are **not exercised**.
There are no observed passes or observed violations in this report.

## Evidence refinements

- Diagnostic recovery tests check an original exception and one subsequent update. Queued waiters and retained state need distinct checks.
- Dependency tests require nonempty diagnostics. Unique markers and valid-to-invalid-to-valid changes provide a stronger freshness oracle.
- Snapshot tests use real loaders and production snapshot creation. Their createProjectA loader wrapper does not exercise production workspace-loading invalidation.
- Script configuration eviction is inside ptestList. It is pending coverage.
- The unchanged-script cache test sends repeated opens with sleeps. It does not perform a close/reopen transition.
- Inlay-hint expected values call the production truncation function. This creates a correlated oracle for truncation.
- Code-fix helpers apply edits and compare text. They do not recompile the edited result in the inspected path.
- VSTest outcome set comparisons can hide duplicate results. Record multiplicity separately.
- The FSDN test body exists, but Program.fs does not register it. No current FSDN outage was verified.
- JsonSerializer has write-only converters. Universal round-trip claims would be invalid for those output contracts.
- AddDto comments describe resetting omitted values. Inspected implementation fields retain prior values. This policy conflict needs resolution before a property oracle is fixed.

## Specific unresolved risks

These are source-derived hypotheses, not executed defects.

1. SourceLink composes a cache path from PDB-derived fragments and trusts existing files. Canonical containment and interrupted-download recovery need direct tests.
2. Project XML edits save directly to the target file. The code does not establish atomic recovery after write failure.
3. DotnetCli redirects stdout. Its WaitForExitAsync helper does not drain output, check an already-exited process, or terminate a canceled child.
4. Shared task Cancel invokes the release action on each call. Repeated cancellation requires an explicit ownership contract.
5. Snapshot stamps and file versions use timestamps. Rapid writes need tests independent of timestamp uniqueness.
6. Server disposal groups and cancellation request stopping. They do not establish termination of uncooperative analyzers, compiler work, or child processes.
7. Config regex parsing drops malformed patterns. Numeric and path settings remain raw values, so successful deserialization does not prove valid configuration.
8. URI and file range APIs accept raw values. UMX tags and Result return types do not prevent all throwing construction paths.

## Catalog balance and method fit

Pure range, token, configuration, and formatter mappings use generated data with independent models.
Stateful document, cache, workspace, and diagnostic properties use real implementation command sequences.
Concurrency cases use barriers that prove the contested operations overlap.
External processes, watchers, disk writes, metadata, and network contracts retain real dependencies.

Proposed test bounds are observation limits, not production latency promises.
A model-only pass cannot establish FSAC behavior.
A timeout does not automatically identify a product defect.
No mutation score, coverage percentage, or broad passing suite is claimed.

The first execution sample should include a pure transformation, a diagnostic transition, and a real project dependency transition.
This sample would evaluate method quality. It would not narrow the repository-wide research scope.

## Unsupported claims

This report does not establish exactly-once diagnostic delivery, durable recovery, global memory bounds, full protocol compliance, cross-platform correctness, or sandboxing.
It does not establish all code-fix variants, all supported F# syntax, or compatibility with every SDK.
No publication, production change, test change, package change, or commit was performed by this research task.

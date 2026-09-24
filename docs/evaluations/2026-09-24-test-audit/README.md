# Test-audit skill evaluation

Date: 2026-09-24. Source snapshot: `dd3efc7aea875260ef9f318990f1407dd96d8f0c`.

The new skill is uncommitted. [Content hashes](skill-hashes.json) identify its evaluated instructions and references.

## Behavioral task

An independent agent received the new skill and an isolated archive of the source snapshot. Its task was:

> Audit all C# and F# executable checks in dotnet-feature-workload/assets/examples for test value, overlap, and runtime contract strength. Keep the audit read-only. Report which checks to retain, repair, consolidate, remove, or leave unresolved, with evidence. Do not run or change code.

The agent received no expected findings or execution results. The [audit](audit.md) records its decisions and inspection limits.

## Observed audit decisions

The audit retained six behavioral checks and marked four checks for repair. It proposed no deletion or consolidation.

It preserved both language consumers and deterministic boundary cases beside generated properties. It distinguished implicit completion assertions from assertion-free execution.

The two repair findings concern example precision: the timer observations allow an intermediate deadline, and the timeout check does not prove clock selection. These are static findings, not executed mutations. The examples were not changed by this task.

No demonstrated skill defect was found in this bounded review. Cleanup behavior and broader audits remain untested.

## Separate execution checks

The parent ran `pwsh -NoProfile -File scripts/verify-examples.ps1` against the unchanged examples. The script completed with exit 0.

| Language | Build | Baseline | Deliberate defect |
| --- | --- | --- | --- |
| C# | Zero warnings and errors | 100 generated cases and deterministic checks passed, exit 0 | Exact-capacity rejection detected, exit 1 |
| F# | Zero warnings and errors | 100 generated cases and deterministic checks passed, exit 0 | Exact-capacity rejection detected, exit 1 |

The selected SDK was 8.0.131 on Windows. Both projects target net8.0 with FsCheck 3.4.0 and Microsoft.Extensions.TimeProvider.Testing 8.10.0. The programs do not emit the executing runtime version.

The deliberate defect exits at the deterministic capacity check. It does not demonstrate mutation sensitivity of the generated property or timer checks.

The example execution checks package behavior. It does not prove the new audit skill makes correct decisions. The independent audit supplies that separate evidence.

## Package checks

- `python scripts/validate-skills.py`: passed for eleven skills.
- The skill-creator structural validator: passed for the new skill.
- `python .ci-scripts/changelog.py validate`: passed. Changelog content was not changed.
- `git diff --check`: passed.
- Local links in the new skill and changed usage documents resolve.

The full external-link and spelling CI tools were unavailable locally. No test deletion, production cleanup, live service, or mutation-tool campaign was performed.

This is a bounded review of executable examples. It does not validate large-suite cleanup, every runner, or every framework combination.

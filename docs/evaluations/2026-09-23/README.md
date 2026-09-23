# .NET repository evaluations: 2026-09-23

Four independent agents applied the skills to isolated public repositories. Each used source revision `0870cc11d332d6c7f027b3b232d9b6dcf5bf0671` of this skill package.

The evaluations preserved each repository's SDK selection, packages, language, framework, and runner. They ran focused checks, not full repository suites.

## Results

| Repository | Request and observed result | Limit |
| --- | --- | --- |
| [Fantomas](fantomas.md) | Formatter workload: 4 tests passed, with 400 generated cases and 8 fixed cases | Restricted generated syntax and four formatting configurations |
| [IcedTasks](icedtasks.md) | Check cancellation behavior and mutation sensitivity: baseline 1 passed, mutant 1 failed, restored 1 passed | Static builder with an already canceled token; exception helper limits broader claims |
| [FsToolkit.ErrorHandling](fstoolkit.md) | Check a Result contract and mutation sensitivity: baseline 2 passed, mutant 2 failed, restored 2 passed | Both Boolean inputs, one error payload, one inverted guard |
| [FsAutoComplete](fsautocomplete.md) | Research and test script-option behavior: 3 passed, 2 skipped | Duplicate-open behavior only; eviction and true reopen behavior were not established |

Each linked report contains the full target revision, commands, execution evidence, and limits. Inline mutation patches are retained where applicable.

## Skill coverage

| Skill | Evaluation |
| --- | --- |
| `dotnet-review-inputs` | Fantomas generator and observation review |
| `dotnet-reliability-research` | Fantomas, FsToolkit.ErrorHandling, FsAutoComplete contract selection |
| `dotnet-feature-workload` | Fantomas generated workload and IcedTasks deterministic test reuse |
| `dotnet-workload` | FsToolkit.ErrorHandling existing workload reuse |
| `dotnet-mutation-testing` | IcedTasks and FsToolkit.ErrorHandling isolated F# source mutations |
| `dotnet-test-triage` | IcedTasks assertion path and FsAutoComplete skipped-test interpretation |
| `dotnet-library-documentation` | FsAutoComplete version and runner evidence |
| `dotnet-test-setup` | FsAutoComplete existing in-process fixture selection only |
| `dotnet-test-setup-k8s` | Not exercised |
| `dotnet-skills-feedback` | Not exercised |

These evaluations do not validate external service provisioning, Kubernetes, Coyote, Stryker.NET, or every documented package version. They do not establish broad product correctness.

## Changes supported by evidence

The feature-workload instructions now explicitly permit existing deterministic tests. The IcedTasks evaluator confirmed that the revised selection remains correct.

The runtime reference now explains FsCheck 3.4.0 single-case replay. Fantomas reach counts exposed the difference between the requested and executed case counts.

The evaluations found no blocking skill defect. Reports preserve test and environment limitations instead of converting them into broader passing claims.

The repository retains ten .NET skills. Service-specific launch, browser authentication, debugger, and timeline-query skills are absent. License notices remain separate from operational instructions.

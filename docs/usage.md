# Use the .NET reliability skills

These skills work with C# and F# source, existing test projects, and .NET runtime contracts. Select the skill for the result you need.

## Choose a starting point

| Your task | Skill | Expected result |
| --- | --- | --- |
| Understand which guarantees need testing | `dotnet-reliability-research` | Prioritized properties with source evidence and suitable test methods |
| Build tests for one feature | `dotnet-feature-workload` | A focused workload that calls the real implementation |
| Implement a property already described in a catalog | `dotnet-workload` | Executable checks and an updated property record |
| Find limits in randomized inputs | `dotnet-review-inputs` | A read-only review of generators, shrinkers, state, and timing |
| Check whether tests notice realistic defects | `dotnet-mutation-testing` | Baseline, isolated mutants, and evidence for each verdict |
| Start the dependencies needed by integration tests | `dotnet-test-setup` | A verified local environment with bounded cleanup |
| Test behavior that requires Kubernetes | `dotnet-test-setup-k8s` | A scoped deployment that preserves the tested cluster behavior |
| Explain a failed, hung, or unexercised test | `dotnet-test-triage` | Runtime evidence, a failure classification, and unresolved alternatives |
| Check an API or runtime guarantee | `dotnet-library-documentation` | An answer matched to the installed version |
| Report a problem with these skills | `dotnet-skills-feedback` | A draft issue for user review |

Use the repository's existing conventions. A pure library does not need containers, and a deterministic regression does not need randomized inputs.

## C# and F# libraries

| Concern | Options | Selection rule |
| --- | --- | --- |
| Generated inputs and shrinking | FsCheck, Hedgehog, existing custom generators | Preserve installed versions and valid domain values |
| Test assertions and discovery | Existing NUnit, xUnit, MSTest, Expecto, TUnit, or other runner | Inspect the project and its execution command before selecting syntax |
| Controlled time | `TimeProvider`, `FakeTimeProvider` | Use only for code that consumes the injected provider |
| Task interleavings | Explicit synchronization or compatible Coyote instrumentation | State which operations and schedules are controlled |
| Real external dependencies | Testcontainers, an existing Aspire AppHost, or Compose | Preserve the dependency behavior required by the property |
| Mutation testing | Compatible Stryker.NET or isolated source mutants | Verify source-language support separately from test-runner support |
| Failure diagnosis | Existing logs, traces, dumps, and .NET diagnostic tools | Collect only evidence that can resolve the specific failure |

Do not migrate a test framework to fit a skill. Do not assume that C# support establishes support for F# source or computation expressions.

FsCheck major versions have different APIs. F# `Async`, `Task`, and `ValueTask` have different start, cancellation, and consumption contracts.

## Work through a property

1. Describe the observable guarantee and its preconditions.
2. Identify the production code and the supported input boundary.
3. Select inputs and an independent expected result.
4. Record a reach condition that a correct implementation can satisfy.
5. For progress, define the trigger, deadline, and environmental assumptions.
6. Run the focused workload and preserve the command, result, and replay evidence.
7. Investigate unexercised or failed checks before changing the guarantee.

For repository-wide requests, research first maps the major subsystems and their contracts. Select a bounded execution sample only after recording research coverage and gaps.

For a larger effort, research produces the catalog and workload skills implement its entries. Setup is needed only when the property requires additional infrastructure.

## Example requests

```text
/dotnet-reliability-research Identify cancellation and disposal guarantees in this F# task library.

/dotnet-feature-workload Test this C# parser with valid domain values and invalid transport inputs. Preserve our test framework.

/dotnet-review-inputs Review the FsCheck generators in these formatter tests. Explain which source shapes they cannot reach.

/dotnet-mutation-testing Establish a baseline and test one realistic F# source mutant in an isolated copy. Keep my checkout unchanged.

/dotnet-test-triage Explain this failed test using its result file, exception, and operation history. Distinguish product failure from harness failure.
```

## Interpret results

- A seed can reproduce generated input under compatible library versions. It does not reproduce arbitrary thread schedules or external systems.
- A wait timeout does not establish that its underlying operation stopped.
- Fake time controls only consumers of that provider. It does not advance every clock in a process.
- A model-only test does not establish behavior of the production implementation.
- A detected mutant demonstrates sensitivity to that defect. It does not prove that every defect will be detected.
- Build failure, generator exhaustion, zero discovered tests, and missing reach observations are distinct from a passing check.

Preserve source revision, relevant configuration, SDK/runtime, package versions, test names, and raw outcomes. For dirty source, retain a patch or file hashes.

## Scope of the package

The package contains ten independently installable skills. It does not include hosted-service launchers, browser authentication helpers, remote debugger drivers, or timeline-query clients.

License and attribution information is in `LICENSE` and `NOTICE`. Operational instructions do not require that history.

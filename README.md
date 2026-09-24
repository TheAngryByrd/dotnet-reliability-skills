# .NET reliability skills

Agent skills for C# and F# property testing, integration workloads, mutation testing, and runtime failure analysis.

The skills use existing .NET libraries and repository conventions. They do not require a hosted testing service.

## Skills

| Skill | Purpose |
| --- | --- |
| [dotnet-review-inputs](dotnet-review-inputs/SKILL.md) | Review generator distributions, shrinking, state, and timing |
| [dotnet-reliability-research](dotnet-reliability-research/SKILL.md) | Discover concrete properties and select suitable test methods |
| [dotnet-feature-workload](dotnet-feature-workload/SKILL.md) | Build a workload for one feature |
| [dotnet-workload](dotnet-workload/SKILL.md) | Implement a property from an existing catalog |
| [dotnet-mutation-testing](dotnet-mutation-testing/SKILL.md) | Check whether realistic defects are detected |
| [dotnet-test-setup](dotnet-test-setup/SKILL.md) | Prepare local hosts and real dependencies |
| [dotnet-test-setup-k8s](dotnet-test-setup-k8s/SKILL.md) | Prepare a scoped Kubernetes test environment |
| [dotnet-test-audit](dotnet-test-audit/SKILL.md) | Audit test value and preserve contracts during cleanup |
| [dotnet-test-triage](dotnet-test-triage/SKILL.md) | Investigate failures using runtime evidence |
| [dotnet-library-documentation](dotnet-library-documentation/SKILL.md) | Verify version-specific APIs and runtime contracts |
| [dotnet-skills-feedback](dotnet-skills-feedback/SKILL.md) | Prepare a reviewable issue for this repository |

## Install

```sh
npx skills add TheAngryByrd/dotnet-reliability-skills
```

Select the skills and agents you need. Restart the agent if it does not discover new skills automatically.

Each skill is self-contained. Installation does not install .NET packages, change test frameworks, or provision services.

## Use

```text
/dotnet-reliability-research Identify reliability properties in src/ and select suitable tests.
/dotnet-review-inputs Review the FsCheck generators in tests/ for unexplored behavior.
/dotnet-feature-workload Exercise cancellation and capacity limits in our new queue feature.
/dotnet-mutation-testing Check whether the F# parser properties detect realistic boundary defects.
/dotnet-test-audit Review these C# and F# suites for redundant or ineffective checks.
/dotnet-test-triage Investigate this failed run using its logs and minimized counterexample.
```

Start with a focused feature workload, or research the system before building a broader catalog. Review findings before adopting new dependencies or infrastructure.

See the [usage guide](docs/usage.md) for skill selection, C#/F# library choices, and the limits of runtime observations.

## Library and runtime choices

- Reuse the repository's test framework, SDK, and package versions.
- Use FsCheck or Hedgehog for generated cases and shrinking when useful.
- Use `TimeProvider` and `FakeTimeProvider` for code that accepts an injected clock.
- Use Testcontainers or an existing Aspire/Compose environment for real dependencies.
- Use Stryker.NET where the source language, project, and runner are supported. Use isolated manual mutations otherwise.
- Consider Coyote only after checking support for the actual execution path.

Seeded input generation does not reproduce thread scheduling or external systems. A timeout does not prove cancellation. A model-only test does not establish production behavior.

## Verification

```sh
python scripts/validate-skills.py
pwsh -NoProfile -File scripts/verify-examples.ps1
```

The executable [C# and F# examples](dotnet-feature-workload/assets/examples/README.md) check FsCheck APIs, timer boundaries, and wait-timeout behavior. Their deliberate boundary defects must fail.

These checks validate structure and examples. They do not certify every library integration or guarantee an agent's decisions.

[Repository evaluations](docs/evaluations/README.md) apply the skills to real source with pinned revisions, executable checks, and explicit limits.

The package contains only the eleven .NET skills listed above. It has no hosted-service launch, browser authentication, remote debugger, or timeline-query skill.

See [prerequisites](PREREQUISITES.md), [contributing](CONTRIBUTING.md), and [license notices](NOTICE).

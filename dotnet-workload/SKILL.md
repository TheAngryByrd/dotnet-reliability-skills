---
name: dotnet-workload
description: Implement or extend C# or F# reliability workloads from an existing property catalog. Map each property to production calls, independent assertions, reach observations, and repository-compatible .NET execution.
license: Apache-2.0
---

# Implement a .NET reliability property

Use this skill when a catalog already describes the property. For feature discovery, use `dotnet-feature-workload` if installed, or perform the needed analysis directly.

## Select the property

Read the requested catalog entry and its evidence. Confirm the source revision and current implementation. Classify coverage as implemented, partial, or absent.

If no property was selected, recommend a small property with a working observation path. Honor an already selected scope without another approval cycle.

If the catalog is missing, document the specific claim and its evidence before implementing it. Do not invent a broad catalog from assertion names alone.

## Implement

1. Inspect the existing test framework, target frameworks, generator library, dependency setup, and runner command.
2. Map each claim to production calls, legal inputs, independent expected results, and a failure signal.
3. Use FsCheck or Hedgehog when generated cases add value. Preserve the installed major version and existing adapters.
4. Include type boundaries and configured limits. Keep shrinkers within the valid domain and preserve operation dependencies.
5. For stateful workloads, track attempted, acknowledged, rejected, and ambiguous operations separately.
6. Retry only failures permitted by the contract. Preserve idempotency keys and ambiguous outcomes.
7. Record reach conditions separately from invariant checks. Include a trigger and a bound for progress properties.
8. Execute the narrow workload and verify that it exercised the intended code. Update the catalog with the actual result.

## Runtime constraints

- Await tasks and asynchronous disposal. Never discard a worker failure.
- Cancellation requests are not proof of termination. Observe the stopped operation and required cleanup.
- A timeout on a wait does not cancel the operation. Bound cleanup separately.
- Fake time requires an injected `TimeProvider`; it does not control `Thread.Sleep`, external services, or unrelated clocks.
- F# `Async` can repeat effects on each start. A `ValueTask` is not necessarily safe for repeated consumption.
- Seeds reproduce generated input, not thread schedules. Record operation histories and tool-specific replay artifacts when available.
- Use framework assertions or a throwing runner. `Debug.Assert` can disappear from release builds.

For a concurrent counter, an acknowledged/attempted bound is valid only if operation semantics, retries, and other writers justify it. Do not apply it universally.

## Output

Use existing test directories and documentation conventions. Otherwise put property evidence under `reliability/properties/<slug>.md`.

Record source revision, command, package versions, runtime, seed, observation bounds, reach results, and the failure mechanism.

If the workload did not exercise the property, report it as not exercised. Do not count an unevaluated assertion as a pass.

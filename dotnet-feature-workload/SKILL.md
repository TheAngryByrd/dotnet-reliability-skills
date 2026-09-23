---
name: dotnet-feature-workload
description: Build or reuse a focused C# or F# test workload for one feature using existing .NET test libraries. Use to exercise invariants, reach conditions, async behavior, and bounded progress locally.
license: Apache-2.0
---

# Build a .NET feature workload

Start with a completed or developing feature. Produce executable checks that call its real implementation, plus a record of what they establish.

## Workflow

1. Read the feature, nearby tests, project files, package versions, and test commands. Preserve the repository's framework and SDK.
2. Identify concrete invariants, input boundaries, failure outcomes, and important reachable states.
3. Separate implemented behavior from planned behavior. Do not disguise an unimplemented requirement as a passing or silently skipped test.
4. Read [runtime semantics](references/runtime.md). Reuse deterministic tests when they cover the contract. For generated cases, select an existing generator or a compatible FsCheck or Hedgehog version.
5. Construct legal domain values through supported constructors. Keep invalid raw input separate to test parsing failures.
6. Build operations, independent expected results, and explicit reach observations. Ensure the workload invokes production code.
7. Use real external dependencies where their behavior is part of the property. Preserve the existing host or container setup.
8. Run a bounded local workload. Record executed cases, rejected cases, reached states, failures, and replay data.
9. Diagnose an unreached state before changing an invariant. Confirm whether a failure belongs to the feature, generator, oracle, or environment.

## Observation semantics

Check safety invariants at each relevant observation. For progress, record the triggering operation and verify completion within the stated bound.

Track reach conditions independently from invariant violations. A correct implementation must be able to satisfy the reach condition.

Do not use `Debug.Assert` as the test oracle. Use the framework's failing assertions or a throwing property runner that produces a failing process exit.

For asynchronous operations, await all work and retain operation IDs, attempts, acknowledgments, and cancellation outcomes. Do not treat every transient error as acceptable.

## Output and iteration

Place workload code in the existing test layout. Otherwise use `tests/` and record analysis under `reliability/features/<slug>/`.

Record the property, source revision, runner command, target framework, runtime, seed or replay token, bounds, and observed result.

Preserve a minimized failing input as a deterministic regression when appropriate. A passing rerun does not erase the original failure.

The [C# and F# examples](assets/examples/README.md) demonstrate FsCheck checks and fake time. They are executable API examples, not a replacement test framework.

## Completion

The workload must execute the real feature, reach the required states, and fail for the intended violation. Report unsupported scheduling or dependency control.

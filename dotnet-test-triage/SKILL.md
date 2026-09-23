---
name: dotnet-test-triage
description: Investigate C# or F# reliability-test failures using runner results, property counterexamples, logs, traces, and source. Use for failed, hung, flaky, or unexercised .NET tests without assuming a specific test platform.
license: Apache-2.0
---

# Triage .NET reliability tests

## Establish what ran

Read the exact command, source revision, SDK/runtime, target framework, package versions, OS, configuration, and environment.

Identify the framework and execution platform separately. Use the repository's runner and its documented result format.

- VSTest commands, executable MTP bridges, and native MTP commands have different argument rules.
- On SDK 10+, native MTP command mode depends on `global.json`; the SDK version alone does not select it.
- Inspect imports and executable/bridge properties before choosing a command.
- Do not apply VSTest filters or logger options to every MTP framework.

Confirm executed test names and counts. A zero-test run, skipped test, generator exhaustion, build failure, or missing report is not a passing test.

## Investigate the failure

1. Preserve the original report and logs before rerunning.
2. Read the complete exception, inner exceptions, counterexample, and relevant task outcomes.
3. Correlate operation IDs, traces, container logs, and source locations. Distinguish event order from causation.
4. Classify the candidate: product defect, assertion defect, generator defect, unexercised property, environment failure, cancellation, timeout, or unresolved.
5. For FsCheck/Hedgehog, retain seed, size, shrink result, original case, and library version. Use the installed version's replay mechanism.
6. For hangs, inspect outstanding operations, cancellation delivery, lock ownership, and disposal. A timed-out wait can leave its operation running.
7. Compare successful and failing executions when that narrows the mechanism. Keep nondeterministic failures visible even when a rerun passes.

Use existing `ILogger`, `Activity`, or OpenTelemetry data first. Collect `dotnet-trace`, `dotnet-dump`, or `dotnet-counters` only when needed and compatible with the target process.

A counter indicates a symptom. A trace or dump supports only what it captured. Match binaries and symbols before interpreting source frames.

Fake time controls only code using the injected provider. F# `Async` starts, task continuations, external I/O, and native code can remain uncontrolled.

## Report

Report the observed result, exact evidence, likely mechanism, unresolved alternatives, and the smallest next action.

Use outcomes such as violated, not exercised, inconclusive, and environment failure. Do not label every nonzero process exit as an assertion violation.

Suggest a workload improvement when reach observations are missing. Suggest mutation testing when sensitivity is uncertain. Do not execute additional work outside the request.

References: [.NET diagnostics](https://learn.microsoft.com/dotnet/core/diagnostics/), [Microsoft.Testing.Platform](https://learn.microsoft.com/dotnet/core/testing/microsoft-testing-platform-intro), [FsCheck](https://fscheck.github.io/FsCheck/).

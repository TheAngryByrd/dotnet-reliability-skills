---
name: dotnet-mutation-testing
description: Evaluate whether C# or F# reliability checks detect realistic source defects. Use Stryker.NET where supported or isolated manual mutants, with a green baseline and per-property failure evidence.
license: Apache-2.0
---

# Validate .NET checks with mutations

The target is the test oracle. One detected mutation shows sensitivity to that defect, not complete correctness.

## Establish scope and baseline

Read the requested properties, actual assertions, build configuration, and test command. Reconstruct missing catalog entries from code, marking the restricted scope.

Confirm the mutation scope, time or execution budget, and whether fixes are authorized. Reuse existing authorization. Do not request the same decision repeatedly.

Run the intended tests against the unchanged source snapshot. Record revision, dirty changes, SDK/runtime, package versions, command, test count, and failures.

Stop on a baseline correctness failure. A skipped, undiscovered, or unexercised test does not establish a green baseline.

## Choose the execution method

Read [mutation execution and verdicts](references/execution.md).

- For supported C# projects, prefer the repository's pinned Stryker.NET tool and configuration.
- For F# source or an unsupported project/runner combination, use isolated manual source mutants with the existing test command.
- C# tests do not establish that a tool can mutate F# source. Verify source-language support separately from test-runner support.

Do not migrate the test framework to make a mutation tool work. Do not silently install a global tool.

## Run and attribute

1. Select a realistic defect that violates the target property, such as a missing guard or boundary comparison.
2. Keep the mutant in a separate worktree or snapshot. Preserve the user's uncommitted files and never mutate their working copy.
3. Build and run the same relevant checks under the same configuration as the baseline.
4. Confirm the mutated code executed and the targeted check failed for the predicted reason.
5. Distinguish survivor, not covered, equivalent, invalid build, timeout, and infrastructure failure.
6. Diagnose the broken link: mutation, reachability, oracle, or property. Do not force a detection by weakening the workload or changing its expected result.
7. If authorized fixes change production code, assertions, or inputs, establish a new baseline and rerun affected mutations within budget.

## Output

Write a report under the repository's evidence directory, otherwise `reliability/mutations/`.

For each mutant, record its patch, property, source fingerprint, command, runtime, execution evidence, verdict, and explanation. Preserve raw tool verdicts.

Remove only temporary resources created by this run after retaining the necessary evidence. Confirm the user's original tree carries no mutant.

Report remaining gaps and budget exhaustion explicitly. Do not turn a mutation percentage into a claim that every property is protected.

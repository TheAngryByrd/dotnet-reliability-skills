# Mutation execution and verdicts

## Stryker.NET

Inspect `.config/dotnet-tools.json`, Stryker configuration, source language, target framework, and runner packages before selecting commands.

Use the installed version's `dotnet stryker --help` and [documentation](https://stryker-mutator.io/docs/stryker-net/introduction/).
Restore the existing local tool manifest when appropriate. Choose a supported version explicitly if the repository has no tool.

Run from the directory expected by that configuration. Preserve include/exclude rules and test filters, and report their effect on scope.

Do not assume the current Stryker release supports F# mutation or every MTP runner. Inspect its compatibility guidance for the selected version.

Retain the machine-readable report when supported. Associate a killed mutation with the responsible test and failure evidence when claiming protection for a specific property.

## Manual C#/F# mutants

Create one isolated snapshot per active mutant. If the baseline contains dirty files, include those exact changes in the snapshot or pause for an explicit baseline choice.

Do not use a clean HEAD worktree as the baseline for tests measured against a dirty original tree.

Change one production expression. Keep tests and expected results unchanged for the initial measurement. Record the patch before building.

Confirm execution through coverage, a debugger observation, or a temporary marker specific to the mutated path. Keep marker changes in the isolated copy.

Avoid stale binaries: build the mutated project and its consumers with the original target/configuration. Record the output assembly used by the runner.

Before removing a worktree, verify its absolute path, ownership, and saved evidence. Never clean an unrelated checkout.

## Verdicts

| Verdict | Required evidence |
| --- | --- |
| Detected | Mutated path executed and intended check failed because of the defect |
| Survived | Mutated path executed but relevant checks passed |
| Not exercised | No evidence that execution reached the mutation |
| Equivalent | A documented argument establishes no observable difference within the scoped contract |
| Invalid mutant | Build failure or a change that does not represent the intended defect |
| Inconclusive | Timeout, infrastructure failure, or missing evidence prevents attribution |

A tool can classify a timeout as a kill. Preserve that tool result, but do not call it an observed invariant violation without supporting evidence.

An F# compiler error caused by a mutation is an invalid mutant, not a test detection. Type-level prevention can be reported separately.

Never refine an assertion to match a mutant and then report the new detection as evidence for the original assertion.

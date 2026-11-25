---
name: dotnet-coyote
description: Use Microsoft Coyote to exercise interleavings and replay concurrency failures in C# or F#. Use when testing shared state, investigating a task race, or checking whether Coyote controls a specific .NET execution path.
license: Apache-2.0
---

# Test concurrent .NET code with Coyote

1. Identify the state owner, competing operations, and observable failure. For example, two successful results from one available permit violate the claim contract.
2. Inspect the target framework, SDK, Coyote CLI and package versions, and concurrency primitives. For F#, also identify FSharp.Core and the computation expression. Use the [F# reference](references/fsharp.md) to check the execution path.
3. Build a small workload in the existing language. Create fresh state for each iteration. Start the competing calls before joining them. Assert the property on their results. Run the correct implementation once on ordinary .NET.
4. Build a disposable copy for rewriting. Include the workload and the assemblies that own the concurrent operations. For multiple assemblies, use a Coyote rewrite configuration. Keep the production binaries separate. [Assembly selection](https://microsoft.github.io/coyote/concepts/binary-rewriting/)
5. Run the rewritten baseline with a stated iteration and step budget. Disable partial control when establishing replay support. Check the reached operations, scheduler statistics, and assertion. A loader error, an unsupported operation, or a failure before the first scheduling decision leaves the path unverified.
6. If the original implementation fails, save its input, rewritten binaries, and trace before changing the code. Replay that trace against those binaries and confirm the same failure. If the baseline passes, introduce a deliberate defect in a disposable copy to check that the workload detects it. Replay the mutant's trace against the same rewritten mutant binaries. Confirm the same assertion and retain that trace separately.

In an existing runner, scope the engine with F# `use` or C# `using`. Check that the runner loaded rewritten assemblies for the workload and state owner. Then call `Run()` and `ThrowIfBugFound()`. [F# runner example](references/fsharp.md#use-an-existing-test-runner)

Report the tool versions, test method, property, controlled operations, exploration bounds, and observed results. Retain the input, rewritten assembly set, trace, and replay command for a failure. An input seed reproduces generated values. The Coyote trace reproduces the scheduler's decisions within the controlled path.

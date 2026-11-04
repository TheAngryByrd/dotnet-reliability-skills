# Stateful and model-based tests in F#

Read this file before you write a test that generates a sequence of operations and compares the system with a model. The runnable source is [Generators/Program.fs](../assets/examples/Generators/Program.fs). It targets FsCheck 3.4.0 and Hedgehog 2.0.4 on .NET 8. For generators and shrinkers of single values, read [F# generators](generators.md).

## Write the specification first

A model needs a written statement of the expected behavior. Before you write a model, list the operations, the guarantees, and the failure modes. Include delivery guarantees, such as at-least-once delivery, and the cases where the system accepts a compromise.

- Use an existing specification, a design document, or the existing tests. If none states a rule, ask the owner or record the rule as an open question. Do not infer the rule from the implementation.
- A failure that the model exposes can be a defect in the system, a defect in the model, or a gap in the specification. Decide which one before you change code.
- Keep the model small. A model that copies the production algorithm shares its defects. The example model is a used count and the last acceptance result. Both come from pure arithmetic.

## FsCheck 3 machine

The FsCheck 3.4.0 README says that the API in `FsCheck.Experimental` is subject to change at any time.

- Inherit `Machine<'Actual, 'Model>(maxCommands)`. Override `Setup` with an `Arbitrary<Setup<_, _>>`, and override `Next model` with a generator of `Operation<_, _>`.
- `Operation.Run model` returns a new model. If the model is mutable, return a new instance.
- `Operation.Check(actual, model)` receives the model after `Run`. Apply the operation to `actual` in `Check`. Compare the value that the operation returns and the observable state with the model. Checking state alone misses a wrong acknowledgement.
- Add `Prop.label` with the request, the model, and the actual values. The runner prints the label for a failure.
- Run the machine with `StateMachine.toProperty machine`. A test can return that property. This works with `[<Property>]` in FsCheck.Xunit and with `testProperty` in Expecto.FsCheck 11.

```fsharp
type PoolOperation(request: Request, observe: PoolModel -> unit) =
    inherit Operation<Pool, PoolModel>()
    member _.Request = request
    override _.Run(model) = modelApply 100 model request
    override _.Check(pool, model) = ...
```

### Preconditions

The example needs no `Pre`, because its model defines the result of every request, including a rejected release. Add `Pre` when an operation depends on an earlier operation, for example a use of an identifier that an earlier operation created. A `Pre` that excludes an operation means the machine never tests that case.

- FsCheck 3.4.0 evaluates `Pre` against the model when it generates a sequence and when it shrinks one. It does not evaluate `Pre` when it runs the sequence.
- During generation, a false `Pre` makes FsCheck draw again. The number of attempts is the larger of 1 and the test size, so at a small size one false `Pre` ends the sequence. Those short runs test little. A `Pre` that is rarely true shortens sequences, and the runner reports them as aborted sequences.
- During shrinking, a false `Pre` drops the operation.
- `Pre` sees only the model. It cannot read the system.
- Put every dependency between operations in `Pre`. Do not rely on `Next` alone, because shrinking removes earlier operations.

### Length and reach

- `Machine(n)` generates exactly `n` operations unless a `StopOperation` is drawn or no operation satisfies `Pre`. `Machine()` follows the test size.
- A passing machine proves nothing about a state that no sequence reaches. Count reach inside the checked operations. The example counts operations whose model fills the pool and fails when the count is zero. It uses a fixed `n` of 20 and a `Next` that ignores the model. It does not generate histories longer than 20 or model-dependent transitions.
- Use `Prop.classify` or `Prop.collect` on the operation name and the target model state to see the distribution. Weight the operations in `Next` toward the states that the specification names.

### Shrinking

- The default `ShrinkOperations` removes one operation at a time. It does not shrink the values inside an operation, so a counterexample keeps its random values.
- To shrink the values, override `ShrinkOperations`. The override receives `Operation` objects, so give the operation type a public member that exposes its request. The example does this with `PoolOperation.Request` and `requestShrink`.
- To shrink the initial state, give `Setup` an `Arbitrary` with a shrinker. `Arb.fromGen` gives no shrinker.
- FsCheck stops after a fixed budget of shrink steps.
- For a value that the system creates, such as an identifier, use `OperationResult<'a>`. Read and write the value with `result.V(operation)` in `Check`. FsCheck records which operations provide and need the value. When the shrinker removes a provider, it also removes the operations that need it. Do not copy a concrete identifier from the system into the model. The example does not use `OperationResult`.

### Setup, teardown, and real dependencies

- `Setup.Actual()` must return a fresh system for each run.
- `TearDown` does not run when `Check` throws. Catch exceptions in `Check` and return a failing property, as the example does, or reset the dependency in `Setup.Actual()`. The example compares the number of teardowns with the number of setups on both passing and failing runs. The `--mutant-throw` defect throws from the system and proves the check.
- FsCheck calls `Check` for every operation, even after an earlier `Check` fails. Later operations then run against a state that already differs from the model. Do not run them against a destructive dependency without a reset.
- Reset a real dependency in each run. Do not share one instance between parallel cases. Two separate settings control parallel runs. `ParallelRunConfig` and the `Parallelism` property of FsCheck.Xunit run the cases of one property in parallel. Leave them off, or give each case its own dependency. Expecto and xUnit run tests in parallel. Put tests that share a dependency in `testSequenced` or an xUnit collection.
- FsCheck runs `Setup.Actual()` and every `Check` again for each shrink candidate. Shrinking can multiply the runs against a real dependency by a large factor.
- The counters in the example are not synchronized. Do not copy them into a test that runs cases in parallel.

### Restart, fault, and time operations

- Model a restart as an operation. After it, compare the system with the durable part of the model. Reopen the store. Do not compare a cache with itself.
- When an operation can fail with an ambiguous result, such as a commit that succeeds and then throws, choose a rule. Put the fault in the operation, so the model knows it. Or let the model accept a set of outcomes, and narrow the set from what the test observes.
- Inject a virtual clock with `TimeProvider`, and make time passing an operation. `FakeTimeProvider` controls only consumers of that provider.

### Runners and replay

| Runner | Version note | Replay |
| --- | --- | --- |
| FsCheck.Xunit 3.x | `[<Property>]` returns `StateMachine.toProperty m` | `Replay = "(seed,gamma,size)"` on the attribute |
| FsCheck.NUnit 3.x | Same attribute model. Not run for this reference | `Replay` on the attribute |
| Expecto.FsCheck 11.x | Uses FsCheck 3. `testProperty name (StateMachine.toProperty m)` | `etestProperty (seed, gamma, Some size)` |
| Expecto.FsCheck 10.x | Uses FsCheck 2. The API in this file does not apply | |

When more than one test ran, the failure output includes `Replay directly at failing step with (seed,gamma,size)`. When the first test fails, the output shows only the original seed. A seed reproduces the generated operations. It does not reproduce thread schedules or external services.

### FsCheck 2

FsCheck 2 has `Command<'Actual,'Model>` and `ICommandGenerator`. FsCheck 3 removes them. Map `RunModel` to `Run`, map `RunActual` and `Post` to `Check`, and map the generator to `Machine`. FsCheck 2 rejects a whole shrunk list when a precondition fails. FsCheck 3 drops only the failing operation.

## Hedgehog

Hedgehog 2.0.x core has no state-machine API.

- Generate a list of commands with `Gen.list`, fold them over a model and the system, and compare after each step. The example does this.
- Shrinking drops commands, so a dependent command, such as a release after a reserve, can become illegal. Make the model and the system handle an illegal command in the same defined way.
- Count reach inside the property, as the example does.
- A separate package, `Hedgehog.Stateful`, offers sequential and parallel specifications and cleanup commands. Version 1.0.0 targets `net8.0`. Version 1.1.x targets `net10.0`. Check the SDK and the package version before you use it. The example does not use this package.

## Concurrency

FsCheck has no parallel command runner. `ParallelRunConfig` runs test cases in parallel. It does not check that concurrent operations are linearizable.

- Test the sequential model first.
- For a concurrent API, run a sequential prefix, then two short branches whose preconditions hold in every interleaving. Record the invocation and the response of each operation. Search for an order that keeps each branch order, keeps every operation that finished before another started in front of it, and matches the model results. If none exists, the history is not linearizable. `Hedgehog.Stateful` offers a parallel specification. Otherwise build the check by hand.
- The thread pool picks the interleaving. A pass covers only the schedules that ran. Repetition raises the chance of a bad schedule and proves nothing. Controlled scheduling needs a tool such as Coyote, within the limits in [runtime semantics](runtime.md).

## Regression tests and checking the model

- Turn each shrunk counterexample into a deterministic test that replays the operations. Write the test before you fix the defect. It must fail on the old code and pass on the new code.
- Check the model with a planted defect. The example has three: `--mutant` rejects an exact fit, `--mutant-ack` returns the wrong acknowledgement and keeps the state correct, and `--mutant-throw` throws from the system. Each stateful check must report `PROPERTY_VIOLATION` for each defect.
- A model test does not find user-interface, security, or performance defects.

Run the example with:

```sh
dotnet run --project assets/examples/Generators/Generators.fsproj
dotnet run --project assets/examples/Generators/Generators.fsproj -- --mutant
dotnet run --project assets/examples/Generators/Generators.fsproj -- --mutant-ack
dotnet run --project assets/examples/Generators/Generators.fsproj -- --mutant-throw
```

Run the commands from the skill directory. The first command must exit 0. The other three must exit 1.

References: [FsCheck](https://fscheck.github.io/FsCheck/), [FsCheck source for `StateMachine.fs`](https://github.com/fscheck/FsCheck/blob/3.4.0/src/FsCheck/StateMachine.fs), [Hedgehog](https://hedgehogqa.github.io/fsharp-hedgehog/), [Coyote](https://microsoft.github.io/coyote/).

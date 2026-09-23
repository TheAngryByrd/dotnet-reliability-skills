# .NET runtime semantics for workloads

Use explicit .NET contracts when designing workload observations.

## Libraries

Reuse installed packages and their APIs. FsCheck 2 and 3 have different namespaces and configuration APIs. Test-runner adapters also differ by major version.

- [FsCheck](https://fscheck.github.io/FsCheck/): generated cases, custom arbitraries, shrinking, classification, and replay in C# or F#.
- [Hedgehog](https://hedgehogqa.github.io/fsharp-hedgehog/): compositional generators with integrated shrinking and seed control.
- [FakeTimeProvider](https://learn.microsoft.com/dotnet/api/microsoft.extensions.time.testing.faketimeprovider): controlled clocks through `Microsoft.Extensions.TimeProvider.Testing`.
- [Testcontainers](https://dotnet.testcontainers.org/): real disposable dependencies when Docker is available.
- [Coyote](https://microsoft.github.io/coyote/): controlled concurrency for supported instrumented code. Verify target framework and API support before adopting it.

## Randomness and replay

Record seed, size, operation sequence, minimized counterexample, package versions, runtime, and configuration. Prefer the library's replay mechanism over a new seed convention.

Seeded generators reproduce inputs under compatible versions. They do not fix task scheduling, process scheduling, filesystem order, network responses, or external clocks.

Do not promise replay from `Random.Shared`. Even an explicitly seeded `Random` requires a stable draw order and compatible implementation.

## Tasks and cancellation

`Task.WaitAsync` can end a wait without stopping its underlying operation. Pass cancellation to the operation, then observe its termination and cleanup.

Cancellation is cooperative. An `OperationCanceledException` alone does not prove that the intended token caused cancellation or that resources were released.

Avoid `async void` except required event handlers. Await task failures. With `Task.WhenAll`, retain individual task outcomes when multiple exceptions matter.

F# `Async<'T>` is a workflow that runs when started. Repeated starts can repeat effects. State cancellation and start options explicitly at task boundaries.

Consume a `ValueTask` according to its producer contract, generally once. Convert once with `AsTask()` when task-style sharing is necessary.

Use `use`, `use!`, `using`, or `await using` as appropriate. Verify disposal after success, fault, and cancellation when that is part of the contract.

## Time and scheduling

Inject `TimeProvider` into the code under test. Advancing `FakeTimeProvider` affects only timers and clocks that use that instance.

Register the timer or wait before advancing fake time. Use a signal to establish readiness when registration occurs asynchronously.

Use a separate real-time watchdog to bound a hung harness. Report watchdog expiry separately from a virtual-time product deadline.

Barriers and completion sources can establish an interleaving. They do not prove all interleavings are safe. Keep Coyote replay claims within its controlled operations.

Do not claim Coyote controls F# `Async`, `MailboxProcessor`, native threads, or external I/O without verifying support for the exact execution path.

## Oracles and input types

Use independent expected results. Repeating the implementation's algorithm or testing only a model can miss the same defect.

Preserve F# private representations, discriminated unions, records, and units of measure. Preserve C# constructor and factory constraints.

Ensure shrinkers preserve domain invariants and dependent operation preconditions. Test malformed transport values at the parser boundary.

Check integer overflow behavior, floating-point NaN/infinity, collection equality, UTF-16 boundaries, and serializer behavior only where the feature uses them.

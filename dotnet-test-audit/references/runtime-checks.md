# C# and F# audit checks

Select checks that match the tested contract. These are audit questions, not reasons to add every test shape.

## Asynchronous completion

- Confirm the runner observes the returned operation. Unawaited tasks and `async void` tests can lose failures, depending on runner support.
- F# `Async<'T>` is a workflow. Constructing it does not establish execution. Check where it starts and which completion is observed.
- Repeatedly starting an F# workflow can repeat effects. Distinguish workflow identity from a shared running task.
- Do not consume a `ValueTask` repeatedly unless its producer guarantees that use. Inspect adapters that convert or cache it.
- Separate cancellation of a wait from cancellation and completion of the underlying operation. `WaitAsync` timeout does not stop its task.
- Check success, fault, and cancellation as distinct outcomes where the contract requires them. A broad exception assertion can hide the wrong outcome.
- For disposal, observe cleanup entry, completion, and effects. A canceled caller does not prove that `DisposeAsync` completed.
- Replace elapsed sleeps with observable synchronization where possible. Require the competing operations to reach the tested interleaving.
- A pending-task assertion needs a reached operation and an observation bound. It must not pass merely because work never started.
- `FakeTimeProvider` controls only consumers of that provider. Advancing it does not advance wall clocks, external services, or every timer.

## Independent observations

- A mock verification can protect ordering or suppression of an effect. A mock that supplies the expected result cannot establish production behavior.
- EF Core InMemory and mocked `DbSet` queries do not establish relational translation, constraints, or transaction semantics.
- An HTTP test using `WebApplicationFactory` can exercise middleware and serialization. It does not automatically cover deployment, TLS, or external identity providers.
- A Testcontainers or Aspire dependency matters only if the tested path uses that instance. Record its selected endpoint and lifecycle.
- Reopen durable state before claiming restart survival. Comparing a cached value with itself is insufficient.
- An authorization denial needs the intended identity, resource ownership, and permission facts. An unrelated guard can make a negative test pass.
- A successful control must reach the same operation with the relevant condition changed. Empty output alone does not establish access denial.

## F# types and generated cases

- Check `Result` and discriminated-union cases, payloads, and effects where they express the contract. `IsSome` alone cannot establish the payload.
- Structural equality is useful for immutable state, but confirm the expected value did not use the transformation under test.
- Check smart constructors and supported deserialization boundaries before generating values through private-representation bypasses.
- For FsCheck or Hedgehog, inspect generator distributions, discarded cases, classification, shrinking, and deterministic boundary examples.
- A property that rejects every interesting input does not protect that behavior. Record accepted and discarded cases when available.
- Retain replay seeds and library versions. Seed replay does not reproduce arbitrary thread scheduling.
- Keep useful fixed regressions beside generated properties when their cases are not guaranteed by generation.

## Compilation and compatibility

- F# inline functions can execute from consumer assemblies. A producer-only rebuild can leave the old implementation in the test binary.
- F# `.fsi` files, ordered `Compile` items, generated source, and linked files can change which API or test is compiled.
- Compare multi-targeted tests by runtime and conditional code, not only their method names.
- Source and reflection checks can protect public signatures, attributes, layout, trimming, AOT, or interoperation contracts. Require the specific contract before removing them.
- Serialization snapshots can protect exact field names, union encodings, or historical data. Do not replace them with a round trip that shares a defect.
- A compile-only test can protect C# overload resolution or F# inference. Require evidence that the intended consumer compiled against the intended assembly.
- Preserve framework-specific discovery and lifetime rules for xUnit, NUnit, MSTest, Expecto, TUnit, or another installed framework.

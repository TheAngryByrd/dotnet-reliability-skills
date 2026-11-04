# F# generators for FsCheck and Hedgehog

Read this file before you write or change an F# generator, shrinker, model, or replay setup. The runnable source is [Generators/Program.fs](../assets/examples/Generators/Program.fs). It targets FsCheck 3.4.0 and Hedgehog 2.0.4 on .NET 8.

Check the installed major version first. FsCheck 2 and FsCheck 3 differ in namespaces, registration, and configuration. Do not copy a snippet from memory into a project on a different major version.

## FsCheck 3

Open `FsCheck` and `FsCheck.FSharp`. The F# modules `Gen`, `Arb`, `ArbMap`, `Prop`, and the `gen { }` builder come from `FsCheck.FSharp`.

| Need | API |
| --- | --- |
| Integer in a range | `Gen.choose (lo, hi)` |
| One of a fixed set | `Gen.elements values` |
| One of several generators | `Gen.oneof gens` |
| Weighted generators | `Gen.frequency [ weight, gen; ... ]` |
| Depend on the test size | `Gen.sized (fun size -> ...)` and `Gen.resize` |
| Collections | `Gen.listOf`, `Gen.arrayOf` |
| Drop values | `Gen.where predicate` |
| Look at output | `Gen.sample count gen` |

- `Gen.where` retries with a growing size until the predicate holds. A rare predicate can hang the test and skews sizes. `Prop.filter` discards cases and can end with exhausted arguments or a vacuous pass. Construct valid values instead.
- Build an `Arbitrary` from a generator with `Arb.fromGen gen`. Add a shrinker with `Arb.fromGenShrink (gen, shrink)`. A property gets no shrinking from `Arb.fromGen` for a custom type.
- Register arbitraries on a class with one static member for each type, for example `static member Quantity() = Arb.fromGenShrink (...)`. A registered arbitrary for a union must shrink the values inside its cases, as `requestShrink` does in the example, or counterexamples keep their large values. Pass the class with `Config.QuickThrowOnFailure.WithArbitrary([ typeof<DomainArbitraries> ])`. Use `Check.One(config, property)` so the registration applies to function arguments.
- Use `Prop.forAll (Arb.fromGen gen) (fun value -> ...)` to bind one generator to one property and skip registration.
- `ArbMap.defaults` is the default registry. Use `ArbMap.mergeArb` and `ArbMap.arbitrary<'T>` to extend and read it.
- Wrap a boolean in `Prop.ofTestable` when an API expects a `Property`. Add `Prop.classify` or `Prop.collect` to measure the distribution.

The example does not exercise a test-runner adapter. With FsCheck.Xunit, list the classes on the attribute: `[<Property(Arbitrary = [| typeof<DomainArbitraries> |])>]`. With Expecto, use `testPropertyWithConfig` and an `FsCheckConfig` that lists the classes in its `arbitrary` field. Confirm the signature against the adapter version in the project, because adapter APIs change between majors.

## Hedgehog

Open `Hedgehog` and `Hedgehog.FSharp`. Do not open `FsCheck.FSharp` in the same scope, because both define `Gen`.

- Every numeric generator takes a `Range`: `Gen.int32 (Range.constant 1 50)` is fixed bounds. `Range.linear 0 40` grows with size. `Range.constantFrom` and `Range.linearFrom` choose the shrink target.
- Combine with `Gen.map`, `Gen.item`, `Gen.choice`, `Gen.frequency`, and `Gen.list (Range.linear 0 40) gen`.
- Write the property with `property { let! x = gen ... }`. End a `unit` property with `do! Property.ofBool condition`, or use a `bool` property with `Property.checkBool` and `Property.reportBool`. `Property.check` accepts only a `unit` property.
- Shrinking is part of the generator. A value shrinks the same way it was made, so a generator that goes through a smart constructor cannot shrink to an invalid value. FsCheck shrinks by type, so a custom type needs its own shrinker.
- Set limits with `PropertyConfig.defaults |> PropertyConfig.withTests 200<tests>`, and run with `Property.checkWith` or `Property.reportWith`.

## Domain values

- Generate values through the production smart constructor, as in `(Quantity.create n).Value` in the example. Generate from a range that the constructor accepts. Do not build a private case by reflection or a second public constructor.
- Keep generators for invalid input separate. Feed them to the parser or the constructor and assert the error.
- Weight union cases to match real use. The example reserves more often than it releases and queries rarely. Check the weights against the state that the property must reach.
- Prove reach. The example counts, inside the checked property, the sequences that fill the pool, and fails if the count is zero. A separate `Gen.sample` run uses a different seed and size, so it does not prove reach for the checked cases. A passing property over sequences that never fill the pool does not test the boundary.

## Model-based tests

Use a model when the property is "the implementation agrees with a simple oracle after every operation".

- FsCheck 3 has `FsCheck.Experimental`. Inherit `Machine<'Actual, 'Model>(maxCommands)`. Override `Setup` with an `Arbitrary<Setup<_, _>>` and `Next model` with a generator of `Operation<_, _>`.
- `Operation.Run model` returns the model after the operation. `Operation.Check(actual, model)` receives that new model, applies the operation to `actual`, and returns a `Property` that compares them.
- Run the machine with `StateMachine.toProperty machine`.
- Write the model so it does not call the production code. The example model is an integer and a pure function.
- For a Hedgehog sequence, generate the list of commands, fold them over a model and the system, and compare after each step.
- Override `Pre` for an operation that has preconditions. FsCheck skips an operation when `Pre` is false, so `Check` must not assume that earlier operations ran. In a Hedgehog sequence, shrinking drops commands, so a dependent command can become illegal. Make the model and the system handle it in the same way.
- `FsCheck.Experimental` is an experimental namespace. Its API can change between versions.

## Replay

- FsCheck prints the seed pair on failure. Replay with `config.WithReplay(Some { Replay.Rnd = Rnd(seed, gamma); Replay.Size = None })`. A `Some size` runs one case at that size, whatever `MaxTest` is.
- The example records the inputs of two seeded runs and fails if they differ.
- Hedgehog failures carry `RecheckInfo`. Serialize it with `RecheckData.serialize` and run `Property.reportRecheck data property`. Treat a recheck that passes as a finding about non-determinism in the property.
- A seed reproduces inputs. It does not reproduce thread schedules, clocks, or I/O.

## Check the generator

Plant a defect at a boundary and confirm that each generator-based check fails. The example flag `--mutant` changes `<=` to `<` in the capacity check. FsCheck sequences, the FsCheck state machine, and Hedgehog sequences must each report `PROPERTY_VIOLATION`.

Run the example with:

```sh
dotnet run --project Generators/Generators.fsproj
dotnet run --project Generators/Generators.fsproj -- --mutant
```

The first command must exit 0. The second must exit 1.

References: [FsCheck](https://fscheck.github.io/FsCheck/), [Hedgehog](https://hedgehogqa.github.io/fsharp-hedgehog/).

# Executable C# and F# examples

These small console workloads verify FsCheck APIs and .NET time semantics. They use FsCheck 3.4.0 and Microsoft.Extensions.TimeProvider.Testing 8.10.0 on .NET 8.

From this directory:

```sh
dotnet run --project CSharp/CSharp.csproj
dotnet run --project FSharp/FSharp.fsproj
```

Each workload checks a capacity predicate against a wider arithmetic oracle. It also checks the exact timer boundary and demonstrates that a wait timeout leaves its underlying operation incomplete.

The generated values stay within the predicate's stated domain: capacity 100, used capacity 0 through 100, and nonnegative requested quantity.

The independent exact-capacity case guarantees observation of that boundary. The random cases do not guarantee coverage of every boundary.

The C# example fixes its FsCheck seed. The F# example uses FsCheck's default seed and reports replay information on a property failure.

To demonstrate a detected boundary defect:

```sh
dotnet run --project CSharp/CSharp.csproj -- --mutant
dotnet run --project FSharp/FSharp.fsproj -- --mutant
```

Both commands must exit 1 with `PROPERTY_VIOLATION: exact capacity was rejected`. Exit 2 means an unexpected harness failure.

The flag selects a deliberately incorrect comparison. This demonstration does not validate Stryker integration or isolated source-mutation tooling.

Fake time controls only the injected timers. The real-time watchdog bounds each await. No result claims deterministic scheduling of the whole runtime.

These are API examples. Use the target repository's actual test framework when implementing a workload.

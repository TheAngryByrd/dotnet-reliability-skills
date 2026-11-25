# Coyote from F#

Use the assembly that owns the F# state. Microsoft documents Coyote for C#. A `Task` return type alone does not establish control over the code that produces it. [Execution model](https://microsoft.github.io/coyote/overview/how/) · [F# tasks and asynchronous workflows](https://learn.microsoft.com/dotnet/fsharp/tutorials/async)

## Run the permit example

Copy the bundled `assets/permit` directory into an empty scratch directory. Run the commands below from the copied directory in PowerShell 7. The example targets .NET 8 and pins Coyote 1.7.11. Use a compatible .NET SDK, .NET 8 runtime, ASP.NET Core 8 runtime, and NuGet access. Keep the target project's own versions when adapting the example. [CLI package](https://www.nuget.org/packages/Microsoft.Coyote.CLI/1.7.11) · [Test package](https://www.nuget.org/packages/Microsoft.Coyote.Test/1.7.11)

```powershell
dotnet tool install Microsoft.Coyote.CLI --tool-path tools --version 1.7.11
dotnet build Claims.fsproj -c Release -o out
dotnet out/Claims.dll
./tools/coyote rewrite out/Claims.dll
$options = @('--iterations', '100', '--max-steps', '1000', '--seed', '42', '--partial-control', 'none', '--enable-memory-access-races')
./tools/coyote test out/Claims.dll --method Locked @options --outdir locked
./tools/coyote test out/Claims.dll --method Unlocked @options --outdir unlocked
./tools/coyote replay out/Claims.dll unlocked/CoyoteOutput/Claims_0.trace --method Unlocked
```

The ordinary executable runs the locked case. The two Coyote tests use the same oracle. Exactly one caller must succeed. The unlocked method contains a deliberate defect. Memory-access scheduling lets Coyote switch callers between reading and clearing the field. In 1.7.11, expect exit 0 for the locked run. The unlocked run and replay should report `Expected exactly one successful claim` and exit 2. Use the trace path printed by the failing run if the filename differs. [Testing and replay](https://microsoft.github.io/coyote/get-started/using-coyote/)

If the SDK and runtime live in separate installations, check `dotnet --list-runtimes` for the host that runs the workload. Use the SDK host for the build. Use the .NET 8 host for `out/Claims.dll`. If the tool shim selects another host, invoke the package's `tools/net8.0/any/coyote.dll` with the same .NET 8 host for rewrite, test, and replay.

## Adapt the workload

| F# execution path | What to check |
| --- | --- |
| Direct `Task.Run`, `Task.WhenAll`, and `lock` | Start with the bundled workload. Move the assertion to the real public result and run it against the actual state owner. |
| `task { let! … }` | Compare the ordinary and rewritten builds. With Coyote 1.7.11, SDK 11.0.100, FSharp.Core 11.0.101, and a .NET 8 host, a rewritten task expression can throw `MissingFieldException` for `TaskStateMachineData` before scheduling. |
| `async { … } |> Async.StartAsTask` | Check the workflow and its caller separately. On the same configuration, the rewritten worker can throw `InvalidProgramException` before the property runs. |
| Mailboxes, native threads, custom schedulers, or external I/O | Identify who schedules each operation. Use a controllable dependency or a real completion signal to establish a specific ordering outside Coyote's control. State which behavior the replacement covers. |

A working harness around a different implementation establishes coverage only for that implementation. A clean bounded run gives evidence for the schedules explored. Preserve the exact F# execution path when reporting a production defect. [Binary rewriting limits](https://microsoft.github.io/coyote/concepts/binary-rewriting/)

## Use an existing test runner

Pass the workload delegate and the assembly that owns the state, such as `typeof<Slot>.Assembly`. Coyote 1.7.11 can log an error and continue when the runner loads an original workload assembly. Check both loaded assemblies before starting the engine. F# `use` releases the engine's event subscription when the test exits.

```fsharp
let runControlled (configuration: Microsoft.Coyote.Configuration)
                  (workload: System.Action)
                  (stateOwner: System.Reflection.Assembly) =
    use engine = Microsoft.Coyote.SystematicTesting.TestingEngine.Create(configuration, workload)
    if not (engine.IsTestRewritten()) then
        failwith "The loaded workload assembly needs rewriting."
    if not (Microsoft.Coyote.Rewriting.RewritingEngine.IsAssemblyRewritten(stateOwner)) then
        failwith "The loaded state-owner assembly needs rewriting."
    engine.Run()
    engine.ThrowIfBugFound()
```

For several state owners, check each assembly that contains operations under test. [Testing engine source](https://github.com/microsoft/coyote/blob/v1.7.11/Source/Test/SystematicTesting/TestingEngine.cs)

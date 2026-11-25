# Coyote and F* for F# codebases

**Use Coyote when the result depends on which caller runs first. Use F* when a rule must hold for every input.** One permit illustrates the difference. F* can prove that a successful claim consumes the permit. Two callers can still read the same old state before either writes the new state. Coyote can exercise that race when it controls the operations involved. [Coyote execution model](https://microsoft.github.io/coyote/overview/how/) · [F* programming model](https://fstar-lang.org/)

## What worked in F#

Local results from 2026-11-24 on Windows x64. The Coyote probe used CLI and test package 1.7.11, .NET SDK 11.0.100, FSharp.Core 11.0.101, and a matching .NET 8.0.34 host for the `net8.0` assembly. The F* probe used v2026.11.22 and built its generated `net10.0` project. [Coyote release](https://github.com/microsoft/coyote/releases/tag/v1.7.11) · [F* release](https://github.com/FStarLang/FStar/releases/tag/v2026.11.22)

| Question | Local result |
| --- | --- |
| Can Coyote schedule two callers of compiled F# code? | With direct `Task.Run` calls and a lock around the claim, 100 iterations completed with zero reported bugs. |
| Can it detect a real defect on that path? | Removing the lock let both callers claim the permit. The assertion failed in iteration 1. Replay reproduced the same assertion. |
| Can it execute an F# `task { let! … }` on this configuration? | The locked case passed before rewriting. After rewriting, it threw `MissingFieldException` for `TaskStateMachineData` before the first scheduling decision. |
| Does `Async.StartAsTask` bring the F# workflow under control? | The locked case passed before rewriting. With a synchronous `Task.WhenAll(...).Result` join, the rewritten worker threw `InvalidProgramException` before the first scheduling decision. |
| Can F* prove a rule and supply code an F# caller can use? | F* verified the claim function and a lemma about a second call. It generated F# that built and ran. A change that kept the permit available failed verification. |

## Test shared state with Coyote

Microsoft documents Coyote for C#. Its rewriter instruments supported operations in compiled assemblies. This makes the emitted calls and their dependencies important for F#. Start with a test-only build of the code that owns the state. If the test and implementation are in separate assemblies, list both in the rewrite configuration. Keep rewritten binaries out of production. [Coyote repository](https://github.com/microsoft/coyote) · [Binary rewriting and assembly selection](https://microsoft.github.io/coyote/concepts/binary-rewriting/)

The following F# workload creates one slot per iteration and starts two callers before joining either. Both results are observable. If both callers read `true` before either writes `false`, both report success.

```fsharp
module Claims

open System
open System.Threading.Tasks
open Microsoft.Coyote.Specifications
open Microsoft.Coyote.SystematicTesting

type Slot() =
    let gate = obj ()
    let mutable available = true

    member _.TryClaim() =
        let accepted = available
        available <- false
        accepted

    member this.TryClaimLocked() =
        lock gate (fun () -> this.TryClaim())

let check claim =
    let start () = Task.Run(Func<bool>(claim))
    let first = start ()
    let second = start ()
    let accepted = Task.WhenAll([| first; second |]).Result
    Specification.Assert(Array.filter id accepted |> Array.length = 1, "Expected exactly one successful claim")

[<Test>]
let Locked() = check (Slot().TryClaimLocked)

[<Test>]
let Unlocked() = check (Slot().TryClaim)
```

### Run the workload

Use a scratch directory with the .NET 8 runtime, ASP.NET Core 8 runtime, and the .NET SDK installed. Save the code as `Claims.fs`. A class library named `Claims.fsproj` needs the following items. Copying local dependencies lets the separate Coyote host load FSharp.Core. [Test package](https://www.nuget.org/packages/Microsoft.Coyote.Test/1.7.11) · [Coyote CLI package](https://www.nuget.org/packages/Microsoft.Coyote.CLI/1.7.11)

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <CopyLocalLockFileAssemblies>true</CopyLocalLockFileAssemblies>
  </PropertyGroup>
  <ItemGroup>
    <Compile Include="Claims.fs" />
    <PackageReference Include="Microsoft.Coyote.Test" Version="1.7.11" />
  </ItemGroup>
</Project>
```

```powershell
dotnet tool install Microsoft.Coyote.CLI --tool-path tools --version 1.7.11
dotnet build Claims.fsproj -c Release -o out
./tools/coyote rewrite out/Claims.dll
$options = @('--iterations', '100', '--seed', '42', '--partial-control', 'none', '--enable-memory-access-races')
./tools/coyote test out/Claims.dll --method Locked @options --outdir locked
./tools/coyote test out/Claims.dll --method Unlocked @options --outdir unlocked
./tools/coyote replay out/Claims.dll unlocked/CoyoteOutput/Claims_0.trace --method Unlocked
```

Memory-access scheduling lets Coyote switch callers between the field read and write. Disabling partial control makes detected uncontrolled operations visible. Save the failing `.trace`, the input, the rewritten binaries, and the tool version together. An FsCheck seed can reproduce input values. Coyote uses the trace to reproduce scheduling decisions. A passing run covers the paths that ran. [Coyote test and replay](https://microsoft.github.io/coyote/get-started/using-coyote/) · [Repository guidance on replay](../../dotnet-feature-workload/references/runtime.md)

For an existing test runner, dispose each engine with F# `use`. Check the loaded workload and state-owner assemblies before calling `Run()` and `ThrowIfBugFound()`. Coyote 1.7.11 can continue after a missing-rewrite diagnostic. [F# runner example](../../dotnet-coyote/references/fsharp.md#use-an-existing-test-runner) For a new F# execution path, first run a working baseline. Then require the expected failure on a deliberately broken implementation and replay its trace. A rewriter exception establishes a compatibility limit. [TestingEngine API](https://microsoft.github.io/coyote/ref/Microsoft.Coyote.SystematicTesting/TestingEngine/)

The two compatibility checks above used the locked implementation. One awaited `Task.WhenAll` inside `task { … }`. The other started each worker with `async { return slot.TryClaimLocked() } |> Async.StartAsTask`. Both completed in the original assembly. The rewritten tests failed before reaching their assertions. For these two shapes, Coyote 1.7.11 did not establish schedule coverage.

Treat `MailboxProcessor`, native threads, custom schedulers, and external I/O as separate compatibility questions. A test can replace an external dependency with a controllable implementation. Use a real completion signal to test a chosen ordering when scheduling control ends at that boundary. [F# asynchronous workflows](https://learn.microsoft.com/en-us/dotnet/fsharp/tutorials/async) · [Coyote rewriting limits](https://microsoft.github.io/coyote/concepts/binary-rewriting/)

## Prove a transition in F* and call it from F#

Write the function and its contract in a `.fst` module. The result below contains two values, the grant decision and the next availability. The refinement fixes both values for every Boolean input. The lemma feeds the first result's state into a second claim and proves that the second claim fails. [F* modules and refinement types](https://fstar-lang.org/tutorial/book/part1/part1_getting_off_the_ground.html)

```fstar
module Permit

let claim (available:bool)
  : r:(bool & bool){ fst r == available /\ snd r == false }
  = (available, false)

let second_claim_fails (available:bool)
  : Lemma (fst (claim (snd (claim available))) == false)
  = ()
```

Save this as `Permit.fst` in a separate directory. Put the release's `bin` directory on the command path. On v2026.11.22, first cache the checked module. Then select the executable function for F# extraction. Older examples that use `--extract` need the current Custard options. [Release binaries](https://github.com/FStarLang/FStar/releases/tag/v2026.11.22) · [Compiler changes](https://github.com/FStarLang/FStar/blob/v2026.11.22/CHANGES.md) · [Custard entry points](https://github.com/FStarLang/FStar/blob/v2026.11.22/doc/ref/custard.md#L1384-L1398)

```powershell
New-Item -ItemType Directory -Force cache | Out-Null
fstar.exe --cache_checked_modules --cache_dir cache Permit.fst
fstar.exe --cache_checked_modules --cache_dir cache --codegen FSharp --custard_entry Permit.claim -o PermitGenerated.fs Permit.fst
dotnet build PermitGenerated.fsproj -c Release
```

The verifier reported `All verification conditions discharged successfully`. Changing the function body to `(available, available)` caused error 19. With a permit initially available, that body violates `snd r == false`.

The generated project compiles `FStarCustard.fs` before `PermitGenerated.fs`. Reference the generated library or compile those files in that order. Our F# caller invoked `PermitGenerated.permit_claim true` and fed the returned state into a second call. It observed one grant followed by one refusal. Check the generated target framework against the application before adopting it. [F# project generator](https://github.com/FStarLang/FStar/blob/v2026.11.22/src/custard/FStarC.Custard.PrintFSharp.fst#L2121-L2147)

### Choose the relationship to existing F# code

- **Ship the extracted function** when a small pure rule can have one implementation. Regenerate it from the verified source in CI. Check any erased input preconditions in the F# wrapper. Match numeric ranges at the boundary. F* mathematical integers and F# `int` have different ranges. Check the extracted operations at the boundaries the proof relies on. For example, v2026.11.22 can return a negative signed remainder where F* proves a nonnegative result. [F# extraction counterexample](../../dotnet-fstar/references/fsharp.md) Review admitted facts before relying on the proof. [F* primitive types](https://fstar-lang.org/tutorial/book/part1/part1_getting_off_the_ground.html) · [F# extraction runtime](https://github.com/FStarLang/FStar/blob/v2026.11.22/src/custard/FStarC.Custard.PrintFSharp.fst#L1858-L2053)
- **Keep the handwritten F# implementation** when replacement is impractical. Use the extracted model as an oracle. Feed the same commands to both implementations and compare the result and next state after each step. A mismatch gives a counterexample. Agreement provides evidence for the tested inputs. The F* proof still applies to the model. I found no official frontend in this release that verifies an existing `.fsproj` directly. [F* compiler input handling](https://github.com/FStarLang/FStar/blob/v2026.11.22/src/parser/FStarC.Parser.Dep.fst#L151-L169)
- **Combine both methods** when a service makes a pure decision and updates shared state. For example, the repository's FsAutoComplete evaluation identifies a shared task that must survive one consumer's cancellation. F* could prove that releasing one of two live references leaves one reference. A Coyote workload could check whether the real wrapper cancels the producer while that consumer is still waiting. First establish scheduling control on that wrapper. The local experiments covered the permit example only. [Shared-task lifetime property and source](../evaluations/2026-09-23/fsautocomplete-research/properties/shared-task-lifetime.md)

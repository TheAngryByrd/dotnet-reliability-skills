# Fantomas skill evaluation — 2026-09-23

## Result

The focused workload calls real Fantomas production code. Four NUnit cases passed with 408 successful formatter cases: 400 generated inputs and eight mandatory boundary inputs. No production defect was observed. An isolated comment-removal mutant failed all four NUnit cases through the idempotency assertion. Final restored-source results appear below.

Evaluated skills revision: `0870cc11d332d6c7f027b3b232d9b6dcf5bf0671`.

Target: fresh shallow clone of `https://github.com/fsprojects/fantomas.git`, default branch `main`, full SHA `4379df8c882f5377b2c83de19d86b6762458d0c1`. Initially clean. Changes are restricted to the isolated evaluation clone. No upstream publication or existing checkout changes.

## System and property research

Fantomas parses F# source with vendored FCS, transforms the AST to Oak, attaches trivia, and prints writer events. There is no persistent store or external service in this property. F# Async workflows start once through Async.RunSynchronously.

| Priority | Property | Oracle | Status |
| --- | --- | --- | --- |
| 1 | Formatting with unchanged configuration reaches a fixed point | Exact ordinal equality between first and second output | Observed pass |
| 1 | Each unique leading/trailing comment occurs once | Regex count against independently generated marker text | Observed pass |
| 2 | Formatted source remains syntactically valid | Public validation API | Observed pass, correlated parser |
| 2 | Output newlines match explicit LF/CRLF configuration | Independent character inspection | Observed pass |

Raw source enters the production parser. The workload constructs a legal grammar for one integer-list binding with two comments. It does not bypass a private representation. Production model changes were unnecessary.

The topology is one local NUnit/VSTest test process, real Fantomas.Core, and real vendored FCS. No model or mock replaces production behavior. The formatter and validation oracle share the parser, so syntax validity is not an independent semantic-equivalence proof.

Research artifacts in the clone: `reliability/research/system.md`, `properties.md`, `properties/list-formatting.md`, `topology.md`, and `evaluation.md`.

## Source evidence

All target links are pinned to the analyzed revision:

- [Public formatter boundary](https://github.com/fsprojects/fantomas/blob/4379df8c882f5377b2c83de19d86b6762458d0c1/src/Fantomas.Core/CodeFormatter.fs#L43-L61).
- [Existing validity, comment, and idempotency checks](https://github.com/fsprojects/fantomas/blob/4379df8c882f5377b2c83de19d86b6762458d0c1/src/Fantomas.Core.Tests/TestHelpers.fs#L42-L88).
- [Empty-list comment regressions](https://github.com/fsprojects/fantomas/blob/4379df8c882f5377b2c83de19d86b6762458d0c1/src/Fantomas.Core.Tests/ListTests.fs#L221-L252).
- [Existing dependent FsCheck generator](https://github.com/fsprojects/fantomas/blob/4379df8c882f5377b2c83de19d86b6762458d0c1/src/Fantomas.Core.Tests/UtilsTests.fs#L33-L54).
- [Repository SDK](https://github.com/fsprojects/fantomas/blob/4379df8c882f5377b2c83de19d86b6762458d0c1/global.json).
- [Package versions](https://github.com/fsprojects/fantomas/blob/4379df8c882f5377b2c83de19d86b6762458d0c1/Directory.Packages.props).
- [Compiler preparation and transformations](https://github.com/fsprojects/fantomas/blob/4379df8c882f5377b2c83de19d86b6762458d0c1/scripts/BuildCompiler.fsx#L16-L85).
- [Pinned compiler file list](https://github.com/fsprojects/fantomas/blob/4379df8c882f5377b2c83de19d86b6762458d0c1/build.fsx#L251-L355).

## Input review

The existing list tests use fixed, issue-specific sources. Their common helper checks syntax, comment sets, and idempotency. Fixed regression examples are suitable here. They are not a deficient randomized workload.

Observation: `TestHelpers.fs` normalizes CRLF before equality. The new workload compares raw public API output and explicitly crosses LF/CRLF settings.

Observation: the utility FsCheck generator uses `Gen.nonEmptyListOf` and chooses an index from zero through length minus one. That preserves its local precondition. It excludes empty lists only for that property. Separate empty-list tests exist. This generator does not generate formatter documents.

The generated workload uses FsCheck 3.4.0. It selects lengths 0–30 and integers -100000–100000. Four NUnit configurations guarantee widths 40/120 and LF/CRLF. Every configuration uses seed 20260923. The final replay has `Size = None`; generator size uses the FsCheck defaults 1–100, but this explicit generator does not consume size. Two deterministic inputs guarantee empty and non-empty boundary cases. Arb.fromGen supplies no shrinker. There are no rejected inputs or conditional preconditions.

Measured counts for each of the four configurations: 102 executed, zero rejected, four empty, 98 non-empty, and 102 changed outputs. These counts include two fixed cases. The same input stream is deliberately repeated across configurations.

Excluded regions: nested lists, Unicode, strings, signatures, directives, arbitrary comment placement, Int32 extremes, malformed source, concurrency, cancellation, and other operating systems. There is no per-operation watchdog. Case count bounds work, but cannot bound a formatter hang.

## Environment and commands

Windows x64. Exact repository SDK installed inside clone `.git/dotnet`: `11.0.100-rc.1.26425.128`. Test target is net10.0. Local runtime is `Microsoft.NETCore.App 11.0.0-rc.1.26425.128`, selected through the test project's existing `RollForward=Major`. Core targets netstandard2.0. FSharp.Core 10.1.203, FsCheck 3.4.0, NUnit 4.6.1, NUnit3TestAdapter 6.3.0, Microsoft.NET.Test.Sdk 18.10.0. SDK, frameworks, package versions, lockfiles, and test runner were preserved.

For reproduction, clone `https://github.com/fsprojects/fantomas.git` and check out `4379df8c882f5377b2c83de19d86b6762458d0c1`. Add the workload and preparation script below.

Commands run from the isolated clone:

```powershell
Invoke-WebRequest https://dot.net/v1/dotnet-install.ps1 -OutFile .git/dotnet-install.ps1
& .git/dotnet-install.ps1 -Version 11.0.100-rc.1.26425.128 -InstallDir .git/dotnet -NoPath
$env:DOTNET_ROOT = (Resolve-Path .git/dotnet).Path
$env:PATH = "$env:DOTNET_ROOT;$env:PATH"
& .git/prepare-deps.ps1
dotnet test src/Fantomas.Core.Tests/Fantomas.Core.Tests.fsproj --filter 'FullyQualifiedName~ReliabilityWorkloadTests' --logger trx --results-directory .git/eval-results-full
dotnet fsi build.fsx -- -p FormatChanged
dotnet fsi build.fsx -- -p AnalyzeChanged
```

`run-tests` was loaded before test execution. The repository has no run-tests overlay. Root AGENTS.md prescribes dotnet test, FormatChanged, and AnalyzeChanged. These commands were retained.

Initial attempts and recoveries:

1. A two-logger test command failed restore with `The name "trx%3bLogFileName" contains an invalid character "%".` A single `--logger trx` avoided that SDK path.
2. A nested `dotnet fsi` could not find the SDK until process-local PATH and DOTNET_ROOT included the exact installation.
3. Compiler initialization failed during FSI NuGet restoration: `error MSB3733: Input file "\*.nuspec" cannot be opened. The filename, directory name, or volume label syntax is incorrect.` No tests ran in these attempts.
4. The retained preparation script fetched the same 90 compiler files at SHA `74ec4f7df70717a162d6ffd23007603cf298fb8b`. It applied the same three text replacements as BuildCompiler.fsx. This is an explicit setup substitution, not a production-code substitution. Later FSI invocations resolved successfully; the original failure cause was not established.
5. First FormatChanged failed because the local Fantomas tool had not been restored. AnalyzeChanged restored the checked-in manifest tools. FormatChanged then passed.
6. First analysis reported nine interpolation annotations and one string conversion type annotation in the new test. Interpolation findings were corrected. One string-conversion advisory persisted with the typed lambda. Explicit invariant formatting resolved it, as recorded below.

## Replay finding and skill assessment

A concrete gap in the runtime reference: F# FsCheck `Replay.Size = Some n` means replay one case, not merely set generator size. The initial configuration combined `WithMaxTest(100)` and `Size = Some 30`. Each NUnit test passed, but FsCheck reported `Ok, passed 1 test.` Instrumented counts were only three, including two fixed cases.

Changing replay to `Size = None` executed 100 generated cases per configuration. This is a harness defect, not a Fantomas defect. The workload skill's requirement to record actual counts detected it.

Version-pinned proof: FsCheck 3.4.0 resolves to `4bcc1d8f172f649f806d124827c7b56e6a8e3980`. [Runner.fs lines 422–431](https://github.com/fscheck/FsCheck/blob/4bcc1d8f172f649f806d124827c7b56e6a8e3980/src/FsCheck/Runner.fs#L422-L431) passes `size.IsSome`. [Lines 239–249](https://github.com/fscheck/FsCheck/blob/4bcc1d8f172f649f806d124827c7b56e6a8e3980/src/FsCheck/Runner.fs#L239-L249) choose `testSingle` when true. Recommended narrow addition: explain this distinction and show F# full-stream replay with Size=None. Use StartSize/EndSize for a size range.

The research skill selected sequential metamorphic properties without introducing concurrency. The input-review skill correctly distinguishes fixed regressions from randomized exploration. The feature skill required real calls, independent reach observations, and throwing assertions. No language, SDK, package, or runner migration was needed. Build prerequisites still required repository-specific investigation.

## Sensitivity check

Before the final integer-formatting edit, an isolated production mutant replaced the selected public overload with:

```fsharp
async {
    let! result = CodeFormatterImpl.formatDocument config isSignature (CodeFormatterImpl.getSourceText source) None
    return { result with Code = result.Code.Replace("// marker-start", "") }
}
```

The same filtered test command with results directory `.git/eval-results-mutant` failed all four tests. On the fixed empty input, the first output retained a blank first line after comment removal. The second formatting removed it. The idempotency assertion detected that difference. This confirms failure sensitivity to this mutation; it does not separately prove the marker-count assertion's sensitivity.

Sanitized failure excerpt:

```text
Unstable source: // marker-start
let values=[] // marker-end
Expected string length 31 but was 30. Strings differ at index 0.
Expected: "\nlet values = [] // marker-end\n"
But was:  "let values = [] // marker-end\n"
Failed: 4, Passed: 0, Skipped: 0, Total: 4
```

Production source was restored byte-for-byte. The first restored run reused the mutant assembly because the copied source kept its old timestamp. That run also failed four tests. A source timestamp refresh forced recompilation before the final rerun. No production mutation remains.

## Reproducible workload

Add one compile item after TestHelpers.fs in `src/Fantomas.Core.Tests/Fantomas.Core.Tests.fsproj`:

```xml
<Compile Include="ReliabilityWorkloadTests.fs" />
```

Create `src/Fantomas.Core.Tests/ReliabilityWorkloadTests.fs` with the following content:

```fsharp
module Fantomas.Core.Tests.ReliabilityWorkloadTests

open System.Text.RegularExpressions
open Fantomas.Core
open FsCheck
open FsCheck.FSharp
open NUnit.Framework

[<TestCase(false, 40)>]
[<TestCase(false, 120)>]
[<TestCase(true, 40)>]
[<TestCase(true, 120)>]
let ``generated lists preserve comments and reach a formatting fixed point`` crlf width =
    let eol = if crlf then EndOfLineStyle.CRLF else EndOfLineStyle.LF

    let config =
        { FormatConfig.Default with
            EndOfLine = eol
            MaxLineLength = width
        }

    let mutable executed = 0
    let mutable empty = 0
    let mutable nonempty = 0
    let mutable changed = 0

    let check (values: int list) =
        let body =
            values
            |> List.map (fun value -> value.ToString(System.Globalization.CultureInfo.InvariantCulture))
            |> String.concat ";"

        let source = $"// marker-start\nlet values=[%s{body}] // marker-end\n"

        let first =
            CodeFormatter.FormatDocumentAsync(false, source, config)
            |> Async.RunSynchronously

        let second =
            CodeFormatter.FormatDocumentAsync(false, first.Code, config)
            |> Async.RunSynchronously

        let valid =
            CodeFormatter.ValidateFSharpCodeAsync(false, first.Code)
            |> Async.RunSynchronously

        Assert.That(valid.IsValid, Is.True, $"Invalid output: %s{first.Code}")
        Assert.That(second.Code, Is.EqualTo(first.Code), $"Unstable source: %s{source}")

        for marker in [ "// marker-start"; "// marker-end" ] do
            Assert.That(Regex.Matches(first.Code, Regex.Escape marker).Count, Is.EqualTo(1), marker)

        let withoutConfiguredNewlines = first.Code.Replace(eol.NewLineString, "")

        Assert.That(
            withoutConfiguredNewlines.Contains('\r')
            || withoutConfiguredNewlines.Contains('\n'),
            Is.False
        )

        Assert.That(first.Code.Contains(eol.NewLineString), Is.True)
        executed <- executed + 1

        if List.isEmpty values then
            empty <- empty + 1
        else
            nonempty <- nonempty + 1

        if first.Code <> source then
            changed <- changed + 1

        true

    let inputs =
        gen {
            let! length = Gen.choose (0, 30)
            return! Gen.listOfLength length (Gen.choose (-100000, 100000))
        }

    check [] |> ignore
    check [ -100000; 0; 100000 ] |> ignore

    let settings =
        Config.QuickThrowOnFailure.WithMaxTest(100).WithReplay(Some { Rnd = Rnd(20260923UL); Size = None })

    Check.One(settings, Prop.forAll (Arb.fromGen inputs) check)
    Assert.That(empty, Is.GreaterThan(0))
    Assert.That(nonempty, Is.GreaterThan(0))
    Assert.That(changed, Is.GreaterThan(0))

    TestContext.Out.WriteLine(
        $"executed=%d{executed}; rejected=0; empty=%d{empty}; nonempty=%d{nonempty}; changed=%d{changed}; seed=20260923; width=%d{width}; eol=%A{eol}"
    )
```

## Exact dependency preparation script

Save as `.git/prepare-deps.ps1`. It is a bounded reproduction of repository initialization.

```powershell
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$hash = ([xml](Get-Content "$root/Directory.Build.props")).Project.PropertyGroup.FCSCommitHash | Where-Object { $_ }
$text = Get-Content "$root/build.fsx" -Raw
$init = $text.Substring($text.IndexOf('pipeline "Init"'))
$init = $init.Substring(0, $init.IndexOf('downloadCompilerFile'))
$paths = [regex]::Matches($init, '"(src/[^"\r\n]+)"') | ForEach-Object { $_.Groups[1].Value }
$paths | ForEach-Object -Parallel {
    $path = $_
    $target = Join-Path $using:root ".deps/$using:hash/$path"
    New-Item -ItemType Directory -Force (Split-Path $target -Parent) | Out-Null
    Invoke-WebRequest "https://raw.githubusercontent.com/dotnet/fsharp/$using:hash/$path" -OutFile $target
    $lines = [IO.File]::ReadAllLines($target) | ForEach-Object {
        if ($_.StartsWith('namespace FSharp.Build')) { $_.Replace('namespace FSharp.Build', 'namespace Fantomas.FCS.Build') }
        elseif ($_.Contains('FSharp.Compiler')) { $_.Replace('FSharp.Compiler', 'Fantomas.FCS') }
        elseif ($_.Contains('[<TailCall>]')) { $_.Replace('[<TailCall>]', '[<Microsoft.FSharp.Core.TailCall>]') }
        else { $_ }
    }
    [IO.File]::WriteAllLines($target, [string[]]$lines)
} -ThrottleLimit 8
"Prepared $($paths.Count) compiler files at $hash"
```


## Final restored result and reassessment

After restoring the production file and refreshing its timestamp:

```powershell
(Get-Item src/Fantomas.Core/CodeFormatter.fs).LastWriteTime = Get-Date
dotnet test src/Fantomas.Core.Tests/Fantomas.Core.Tests.fsproj --filter 'FullyQualifiedName~ReliabilityWorkloadTests' --logger trx --results-directory .git/eval-results-restored
```

Exit code 0. `Failed: 0, Passed: 4, Skipped: 0, Total: 4`, duration 735 ms. Each test reported `Ok, passed 100 tests.` Reach counts remained 102 executed, zero rejected, four empty, 98 non-empty, and 102 changed. Total successful cases: 408.

Final FormatChanged passed. AnalyzeChanged exited 0, but inspection of `analysis.sarif` found one remaining `GRA-TYPE-ANNOTATE-001` advisory: `Please annotate your type when using the string function.` The typed lambda did not satisfy that analyzer. This was not a clean analyzer result. The advisory was resolved in the follow-up below.

`git diff --quiet -- src/Fantomas.Core/CodeFormatter.fs` exited 0. No production mutant remains. Raw local TRX and logs remain under clone `.git/`; publication uses these sanitized excerpts and reproducible source.

The parent added narrow FsCheck replay guidance in `dotnet-feature-workload/references/runtime.md`. I reviewed its exact wording against the executed counts and pinned runner source. It correctly distinguishes single-case replay from a seeded campaign. No additional skill change is supported by this evaluation.

| Requirement | Evidence |
| --- | --- |
| Identify a useful formatting reliability property | Fixed-point, comment, syntax, and newline properties above |
| Review relevant existing test inputs | Pinned ListTests, TestHelpers, and UtilsTests input review above |
| Implement and run a focused workload that calls Fantomas production code | `generated lists preserve comments and reach a formatting fixed point`, four parameter combinations, final 408 cases passed |


## Final advisory resolution

Replaced `string value` with `value.ToString(System.Globalization.CultureInfo.InvariantCulture)` in the new test. Production code was not modified. The reproducible source above contains this final version. SHA256: `23403714746C663AABB88B18DBFD043887CE2AAAC5081FD64C7AADAB11FF9290`.

Executed after this edit:

```powershell
dotnet fsi build.fsx -- -p FormatChanged
dotnet test src/Fantomas.Core.Tests/Fantomas.Core.Tests.fsproj --filter 'FullyQualifiedName~ReliabilityWorkloadTests' --logger trx --results-directory .git/eval-results-advisory
dotnet fsi build.fsx -- -p AnalyzeChanged
```

All three commands exited 0. The test summary was `Failed: 0, Passed: 4, Skipped: 0, Total: 4`, duration 762 ms. Each configuration executed 100 generated cases and two fixed cases. Each reported zero rejected, four empty, 98 non-empty, and 102 changed outputs. Total: 408 successful cases. Final `analysis.sarif` contained zero results.

The mutation evidence above belongs to the prior workload revision with generic integer conversion. The mutation was not rerun after this formatting-only conversion edit. The assertions, seed, input bounds, and required reach observations are unchanged.

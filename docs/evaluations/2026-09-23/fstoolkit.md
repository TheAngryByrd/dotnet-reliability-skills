# FsToolkit.ErrorHandling evaluation

Date: 2026-09-23. Evaluated skills: `dotnet-reliability-research`, `dotnet-workload`, and `dotnet-mutation-testing` at `0870cc11d332d6c7f027b3b232d9b6dcf5bf0671`.

## Result

The existing `Result.requireTrue` checks detected an inverted production guard. Both Boolean cases passed on the baseline and failed on the mutant. Both cases passed again after source restoration.

This establishes sensitivity to one guard inversion. It does not establish complete correctness or a repository-wide mutation score.

## Repository and execution

- Repository: https://github.com/demystifyfp/FsToolkit.ErrorHandling.git
- Default branch: `master`.
- Full source SHA: `d482e196cc3333e820355a0e412e01111944f3a7`.
- Initial tracked state: clean fresh clone. The mutant used a second isolated clone inside the evaluation clone's `.git/eval-mutant` directory.
- OS: Windows 10.0.26200, win-x64.
- `global.json`: SDK `10.0.100`, `rollForward: latestMinor`. Selected SDK: `10.0.401`; MSBuild `18.9.11+e34a38d2a`.
- Selected test and production framework: `net9.0`; language version `9.0`; FSharp.Core `9.0.300`.
- Actual mutant runtime marker: `.NET 9.0.20`. Baseline and restored runs used the same host and framework configuration.
- Package manager: NuGet with central package management, unchanged.
- Framework: Expecto `10.2.3`. Adapter: YoloDev.Expecto.TestSdk `0.15.3`. Microsoft.NET.Test.Sdk `17.4.1`.
- Runner: repository-compatible `dotnet test` in VSTest mode. No SDK, dependency, runner, or package-manager changes.
- Inspected instructions: root `AGENTS.md`; no nested `AGENTS.md` or run-tests overlay. Read the installed `run-tests` skill before .NET execution.
- Inspected configuration: root/src/tests build props, central packages, `global.json`, production/test project files, tool manifest, build target, and test entry point.

The build target uses `DotNet.test`. The focused command retains this runner and builds the selected project. It does not run the full solution build target.

## Property and evidence

Slug: `require-true`. Priority: selected input-boundary contract.

For each Boolean input `b` and supplied error `e`, `Result.requireTrue e b` returns `Ok ()` when `b` is true. It returns `Error e` when `b` is false.

- Production: [`src/FsToolkit.ErrorHandling/Result.fs:274-284`](https://github.com/demystifyfp/FsToolkit.ErrorHandling/blob/d482e196cc3333e820355a0e412e01111944f3a7/src/FsToolkit.ErrorHandling/Result.fs#L274-L284).
- Contract documentation: `gitbook/result/requireFunctions.md:3-34`.
- Reused workload: `tests/FsToolkit.ErrorHandling.Tests/Result.fs:291-302`.
- Independent throwing assertions: `tests/FsToolkit.ErrorHandling.Tests/Expect.fs:25-35`.
- Registration: `tests/FsToolkit.ErrorHandling.Tests/Result.fs:968` and `Main.fs:15`.

Input domain: both Boolean values. Error payload used: `"foobar"`. Preconditions: none. Observation bound: synchronous return. Reach condition: both selected tests execute the helper. Fault model: invert the Boolean guard. Expected signal: each test observes the wrong Result alternative.

The two existing tests exhaust the Boolean domain for this error payload. Generated cases add no value for this selected domain. No FsCheck/Hedgehog dependency or seed was needed. Workload patch: empty. Test assertions and inputs remained unchanged throughout.

This is a pure synchronous helper with no state, persistence, serialization, or services. A real project reference builds production code. The helper is inline, so its production implementation can execute inside the rebuilt test consumer. Both projects were rebuilt for the mutant and restoration.

`Result<unit,string>` preserves success/error alternatives. It does not preserve the input Boolean as a proof-bearing domain value. No domain model was changed.

## Commands and outcomes

Clone the default branch, then capture `git rev-parse HEAD`, `git status --short`, `git branch --show-current`, and `dotnet --info`.

For reproduction, check out `d482e196cc3333e820355a0e412e01111944f3a7` before running the commands below.

Baseline command, from the fresh clone:

```powershell
dotnet test tests/FsToolkit.ErrorHandling.Tests/FsToolkit.ErrorHandling.Tests.fsproj -f net9.0 -c Release --filter 'FullyQualifiedName~Result Tests.requireTrue Tests' --logger 'console;verbosity=detailed' --logger 'trx;LogFileName=baseline.trx' --results-directory reliability/mutations/baseline
```

Create the isolated mutant with `git clone --shared . .git/eval-mutant`. Apply only the production patch below. From that snapshot, use the same command and filter. Change only the TRX filename to `mutant.trx` and result directory to `../../reliability/mutations/mutant`.

Restore with `git -C .git/eval-mutant restore -- src/FsToolkit.ErrorHandling/Result.fs`. Repeat the same test command from the snapshot. Use `restored.trx` and `../../reliability/mutations/restored`.

| Run | Exit | Passed | Failed | Skipped | Verdict |
| --- | ---: | ---: | ---: | ---: | --- |
| Baseline | 0 | 2 | 0 | 0 | Observed pass |
| Mutant 1 | 1 | 0 | 2 | 0 | Detected |
| Restored | 0 | 2 | 0 | 0 | Observed pass |

Exact selected test names:

- `All Tests.Result Tests.requireTrue Tests.requireTrue happy path`
- `All Tests.Result Tests.requireTrue Tests.requireTrue error path`

Budget used: one baseline, one mutant attempt, one restored verification. Two permitted mutant attempts remained unused.

## Exact mutation and attribution

```diff
--- a/src/FsToolkit.ErrorHandling/Result.fs
+++ b/src/FsToolkit.ErrorHandling/Result.fs
@@
     let inline requireTrue (error: 'error) (value: bool) : Result<unit, 'error> =
-        if value then Ok() else Error error
+        System.Console.Error.WriteLine("MUTANT_REQUIRE_TRUE_REACHED value={0}; runtime={1}", value, System.Runtime.InteropServices.RuntimeInformation.FrameworkDescription)
+        if not value then Ok() else Error error
```

The semantic defect is one guard inversion. The extra statement records execution and runtime. It does not change the expected result or input. The marker and defect were confined to the isolated snapshot.

Observed output:

```text
MUTANT_REQUIRE_TRUE_REACHED value=False; runtime=.NET 9.0.20
MUTANT_REQUIRE_TRUE_REACHED value=True; runtime=.NET 9.0.20
Failed All Tests.Result Tests.requireTrue Tests.requireTrue error path
Expected Error, was Ok(()).
Failed All Tests.Result Tests.requireTrue Tests.requireTrue happy path
Expected Ok, was Error("foobar").
Total tests: 2
     Failed: 2
Test Run Failed.
```

Stack traces identify the unchanged assertions at `Expect.fs:27` and `Expect.fs:35`, called by the selected cases at `Result.fs:300` and `Result.fs:295`. This is an observed assertion violation, not a build error, timeout, or discovery failure.

Source SHA-256:

| File/version | SHA-256 |
| --- | --- |
| Production `Result.fs`, baseline | `1754A14B3BA7597BC59DDEABFB2563B40B4236AD9B6AD1AC50FBFE7D37663D28` |
| Production `Result.fs`, mutant | `9AD50D9A4496C474356624BD3123D8A8909A3C8898BFA9536DD451F086AC8CC6` |
| Test `Result.fs`, unchanged | `00CA5FAA0EC97B42BDE880227E0C11FEF92227CD283C4EF7067CA59D2A8C263E` |
| Test `Expect.fs`, unchanged | `23414DF6B38F3D940FA3C4CC587EC2A0F18B5742C9599C2634FC36EF3408D74B` |

The runner used `tests/FsToolkit.ErrorHandling.Tests/bin/Release/net9.0/FsToolkit.ErrorHandling.Tests.dll` in each respective clone. Production output was `src/FsToolkit.ErrorHandling/bin/Release/net9.0/FsToolkit.ErrorHandling.dll`.

| Assembly/version | SHA-256 |
| --- | --- |
| Baseline test | `D2CBBAD95E314B0CD58E3708ACD7B34EE1C9DC5275DE91F2A190A71509DF69E0` |
| Baseline production | `809ED946ED34A0F77D76D3DA4B919167ED0EAF10F22499CB32CF85748FF1D969` |
| Mutant test | `92B21270FDD28468E8CA70A3254406D86056186886C47F57D9EA51081EF586BB` |
| Mutant production | `FE83D15CFAD262CB89E2E581C76F8F427B3D22209CF3F14D662DEDF74235957D` |

## Skill assessment and limits

All three skills supported this task without framework migration or new test dependencies. The research skill supplied the property record. The workload skill correctly permitted reuse. The mutation skill supplied the F# manual-mutant route and required direct execution evidence.

No blocking skill defect was found in this evaluation. Research required five evidence documents for one small pure contract. That is administrative cost, not a correctness defect. One useful refinement is an explicit reminder that inline F# production functions require rebuilding their consumers. The mutation reference already requires rebuilding consumers, which was sufficient here.

F# production source and the absence of pinned Stryker configuration selected the documented manual route. No global mutation tool was installed. Stryker compatibility was not tested or claimed.

Gaps: only one error payload and one semantic mutant. Other Result/Option functions, computation expressions, net8.0, Fable targets, concurrency, and full-suite compatibility were not evaluated. No broad reliability or performance conclusion follows.

Local evidence remains under the evaluation clone's `reliability/`: research records, mutation patch, console logs, and TRX files. This report omits local usernames and machine-specific absolute paths. Raw local logs were not published.

Cleanup verification: the original clone has no tracked changes. The isolated snapshot also has no tracked changes. No source marker remains. The restored production source hash equals the baseline hash. Both clones remain as local evidence.


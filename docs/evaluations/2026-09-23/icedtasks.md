# IcedTasks behavioral evaluation

Date: 2026-09-23

## Result

**Detected.** One existing test detected removal of the cancellation guard in the static `CancellableTaskBuilder.Run` implementation. The baseline and restored source passed.

| Execution | Exit code | Passed | Failed | Skipped | TRX test duration |
| --- | ---: | ---: | ---: | ---: | ---: |
| Baseline | 0 | 1 | 0 | 0 | 240 ms |
| ICED-M001 | 1 | 0 | 1 | 0 | 280 ms |
| Restored | 0 | 1 | 0 | 0 | 235 ms |

This result establishes sensitivity to one missing cancellation guard. It does not establish complete cancellation correctness or coverage of all schedules.

## Revisions and environment

- Skill revision: `0870cc11d332d6c7f027b3b232d9b6dcf5bf0671`.
- Repository: `https://github.com/TheAngryByrd/IcedTasks.git`.
- Default branch: `master`.
- Source revision: `c51e9fc63fb0c78887f5c418b0530453a2b2cf80`.
- Clean baseline, no test edits, no package or project changes.
- OS: Windows `10.0.26200`, `win-x64`.
- SDK: `10.0.401`, MSBuild `18.9.11+e34a38d2a`.
- Existing `global.json`: SDK `10.0.100-rc.1.25451.107`, `rollForward: latestMinor`. It selected the installed SDK without changes.
- Test target: `net10.0`, Release. Referenced library target: `net9.0`.
- Runtime: `Microsoft.NETCore.App 10.0.12`, the only installed 10.0 runtime. Runtime configuration requests `10.0.0` with normal patch selection.
- Relevant existing environment: `DOTNET_GCDynamicAdaptationMode=1`, `DOTNET_ROLL_FORWARD_TO_PRERELEASE=1`, `DOTNET_gcServer=1`.
- Executed dependency versions: Expecto `10.2.3`, Expecto.FsCheck `10.2.3`, FsCheck `2.16.5`, FSharp.Core `9.0.300`, Microsoft.NET.Test.Sdk `17.7.2`, YoloDev.Expecto.TestSdk `0.15.3`.
- Existing local tools were restored by the repository build: fsharp-analyzers `0.33.1`, fantomas `8.0.0-alpha-017`, fsdocs-tool `20.0.0-alpha-018`.

The repository has no `AGENTS.md` or `run-tests` overlay. The root and project build imports, package definitions, tool manifest, and `build/build.fs` test command were inspected.

The framework is Expecto. Its YoloDev adapter executes through VSTest. No native MTP selection or bridge configuration applies.

## Contract and workload

Property: constructing a cancellable task must not run its body. Starting that task with an already canceled token must also prevent its body effects.

The existing test supplies a deterministic workload:

`IcedTasks.CancellableTask.CancellableTaskBuilder.Cancellation Semantics.CancellableTasks are lazily evaluated`

Source: `tests/IcedTasks.Tests/CancellableTaskTests.fs:1133`.

1. Initialize `someValue` to `null`.
2. Construct a task whose body sets `someValue` to `"lol"`.
3. Await 100 ms and assert that the body has not run.
4. Cancel a fresh `CancellationTokenSource` before starting the task.
5. Start the task with that token.
6. Await another 100 ms and check the body effect.
7. Observe the cancellation through the existing helper.
8. Assert `someValue = null` outside that helper at line 1156.

The oracle checks an observable effect, independently of the production cancellation condition. The test invokes the real builder.

Exactly one test ran in each execution. There were no generated or rejected inputs. Seed, size, shrink result, and replay token are not applicable. The fixed operation sequence is the replay input.

The test uses real `Async.Sleep` delays. They do not control task scheduling. A 60-second VSTest hang watchdog bounds test execution separately from those delays. No watchdog expired.

The inner body has no asynchronous work. In the mutant execution, it completes synchronously before the failure. No unfinished inner operation remains after that failure.

## Commands and isolation

The following commands use a relative owned clone path. All mutation work occurred inside that clone. No original user checkout was accessed or changed.

```powershell
git clone https://github.com/TheAngryByrd/IcedTasks.git icedtasks
git -C icedtasks checkout --detach c51e9fc63fb0c78887f5c418b0530453a2b2cf80
```

From the clone root:

```powershell
git rev-parse HEAD
git branch --show-current
dotnet --info
dotnet test tests/IcedTasks.Tests/IcedTasks.Tests.fsproj -f net10.0 -c Release --filter 'FullyQualifiedName~CancellableTasks are lazily evaluated' --logger 'trx;LogFileName=baseline.trx' --results-directory .git/evaluation --blame-hang --blame-hang-timeout 60s
git worktree add --detach .git/eval-mutant HEAD
```

From `.git/eval-mutant`, after applying the patch below:

```powershell
dotnet test tests/IcedTasks.Tests/IcedTasks.Tests.fsproj -f net10.0 -c Release --filter 'FullyQualifiedName~CancellableTasks are lazily evaluated' --logger 'trx;LogFileName=mutant.trx' --results-directory ../evaluation --blame-hang --blame-hang-timeout 60s
git diff -- src/IcedTasks/CancellableTask.fs
git restore --source=HEAD -- src/IcedTasks/CancellableTask.fs
dotnet test tests/IcedTasks.Tests/IcedTasks.Tests.fsproj -f net10.0 -c Release --filter 'FullyQualifiedName~CancellableTasks are lazily evaluated' --logger 'trx;LogFileName=restored.trx' --results-directory ../evaluation --blame-hang --blame-hang-timeout 60s
git diff --exit-code
git status --short
```

Each test command rebuilt production code and its test consumer. This matters because `Run` is inline F# code. No `--no-build` command was used.

Raw console logs and TRX files remain in the clone's `.git/evaluation/` directory. Names are `baseline`, `mutant`, and `restored`, with `.log` and `.trx` extensions. The patch is `mutant.patch`.

Budget used: one baseline, one mutant execution, one restoration verification. An initial patch match check failed before making edits or executing tests. No additional mutant attempts ran.

## Exact mutant and reach evidence

The realistic defect replaces the static entry guard with `false`. A temporary diagnostic marker records entry and the actual token state.

```diff
diff --git a/src/IcedTasks/CancellableTask.fs b/src/IcedTasks/CancellableTask.fs
index f364943..0ab20c4 100644
--- a/src/IcedTasks/CancellableTask.fs
+++ b/src/IcedTasks/CancellableTask.fs
@@ -131,7 +131,7 @@ match __stack_exn with
                         let sm = sm
 
                         fun (ct) ->
-                            if ct.IsCancellationRequested then
+                            if (System.Console.Error.WriteLine("ICED-M001 static Run ct={0}", ct.IsCancellationRequested); false) then
                                 Task.FromCanceled<_>(ct)
                             else
                                 let mutable sm = sm
```

The mutation changes one production condition. The marker does not change the token, task result, body effect, or oracle. The dynamic implementation remains unchanged.

The mutant TRX records:

```text
ICED-M001 static Run ct=False
ICED-M001 static Run ct=True
```

The test failure is:

```text
expected: <null>
  actual: "lol"
```

The failing frame identifies `tests/IcedTasks.Tests/CancellableTaskTests.fs:1156`. The canceled-token marker proves that the changed condition executed. The changed body effect explains the assertion failure.

The restored execution passed with the same test and configuration. Its output contains no mutation marker. Both source trees were clean after restoration.

## Failure triage and limits

Classification: deliberately injected product defect, detected by an unchanged assertion. It was not a build failure, timeout, undiscovered test, or infrastructure failure.

The exception helper needs separate review. In `tests/IcedTasks.Tests/Expect.fs:99`, `throwsTAsync` fails when the caught type is assignable from the expected type. It accepts other caught exceptions. This condition is inverted relative to its stated purpose.

The helper can therefore hide the first body-effect assertion inside its argument. The final assertion at line 1156 remains outside the helper and detects the mutant. The observed failure comes from this final assertion.

Do not use this experiment as proof of exception-type matching, token identity on the thrown exception, or reliable behavior of every cancellation helper overload. No helper fix was attempted.

The evaluation covers the static `CancellableTaskBuilder.Run` path only. It does not cover dynamic builders, background builders, cancellation races, disposal, other target frameworks, or generated input populations.

Manual F# mutation was selected from the skill instructions. Stryker.NET was not installed or invoked. No claim about Stryker F# support follows from this run.

## Fingerprints

SHA-256 values identify the source and runner artifacts observed during execution.

| Artifact | Baseline | Mutant | Restored |
| --- | --- | --- | --- |
| `src/IcedTasks/CancellableTask.fs` | `132421B169B6771AFD98E96E0FE7D3845A2BD53DF8D3AC6B87B9C1DBE0073035` | `71867EBBFB1C2A2CB30CD6B4E579BEA454D5BC14636F7F080F54ABB94CADF86E` | `132421B169B6771AFD98E96E0FE7D3845A2BD53DF8D3AC6B87B9C1DBE0073035` |
| `src/IcedTasks/bin/Release/net9.0/IcedTasks.dll` | `336C215908CEFCFCB604E91ECB0FD5F71389CEC3319322499585698EBCB306C3` | `81270128569BA80AC5A064DA4439D08BA274F31562EF969FCAB938879D57754E` | `57586477A4EFEE8DE42C767C5AEF791A4E0DDE73DE42BBD24B8EEAC74D30E668` |
| `tests/IcedTasks.Tests/bin/Release/net10.0/IcedTasks.Tests.dll` | `9CCF17F039CB9A0A2E076D27C9EB6A71440376C31D7E461BFE208CA7901B7CC3` | `787E8F454283297843C4608B54F0C3C4C0EED4479BF2B5B8CB66C5542F143F88` | `DC23290D801F621B33AEBA794DB500768D379DC0C4C0DB2ACA93C64F57D76C69` |

The original and restored source share Git blob `f364943e011c8ee1fac95272facbc9ad14419c73`. Binary byte equality was not required or established across separate paths and builds.

## Skill evaluation

- `dotnet-feature-workload` directed property selection, production execution, independent observations, explicit bounds, and scheduling limits. The existing test met this request without new test code.
- `dotnet-mutation-testing` correctly selected isolated manual F# mutation. Its rebuild and marker requirements prevented unsupported language-support and stale-binary claims.
- `dotnet-test-triage` directed inspection of the exact test count, failure frame, and exception helper. That inspection restricted the cancellation claims appropriately.

No blocking skill defect was observed. One non-blocking wording gap remains: feature-workload step 4 requires generator selection without an explicit existing-test path. This request explicitly allowed an existing deterministic test. The skill should make that option clear when it already exercises the requested contract.

No SDK, framework, package, skill, or upstream changes were made.

After evaluation, feature-workload steps 4–5 were changed to explicitly permit existing deterministic tests. The evaluator reviewed the new wording against this task. The wording gap is resolved, and the test selection remains correct. Runtime results above remain associated with the original skill revision.

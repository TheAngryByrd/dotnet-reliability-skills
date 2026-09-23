# FsAutoComplete focused script-options evaluation

Date: 2026-09-23.
Skill revision: `0870cc11d332d6c7f027b3b232d9b6dcf5bf0671`.
Target: <https://github.com/ionide/FsAutoComplete>.
Target default-branch revision: `85886b187b87834e0fe0a410cb13332d7f9757ca`.

This evaluation covers one script-options behavior. It does not establish repository-wide research coverage. See the [repository-wide research rerun](fsautocomplete-research/system.md).

## Result

**Observed pass:** duplicate opening of an unchanged, still-open script produced one script-options event in both compiler modes.
The test host also passed its runtime-major assertion.
**Not exercised:** script option invalidation after argument changes. Both existing cases are disabled with `ptestList`.
No product defect was demonstrated.

| Run | Exit | Passed | Failed | Skipped | Runner time |
| --- | --- | --- | --- | --- | --- |
| Script eviction | 0 | 0 | 0 | 2 | 3.1164 seconds |
| Script options cache plus runtime guard | 0 | 3 | 0 | 0 | 31.9846 seconds |

The first command printed `Test Run Successful` despite skipping every selected test.
The triage skill correctly requires an unexercised result for that property.

## Environment and version evidence

The evaluation used a fresh clone. No original checkout, global installation, upstream branch, or skill file was changed.
`AGENTS.md`, `CONTRIBUTING.md`, project files, imported properties, Paket files, test fixtures, and runner initialization were inspected.
`.agents/skill-overlays/dotnet-test/run-tests.md` was absent. The installed `run-tests` skill was read before execution.

| Item | Observed configuration |
| --- | --- |
| OS | Windows 10.0.26200, win-x64 |
| SDK | 10.0.401, commit e34a38d2ae |
| MSBuild | 18.9.11+e34a38d2a |
| global.json | 8.0.300, rollForward latestMajor, allowPrerelease true, unchanged |
| Test frameworks | net8.0;net9.0;net10.0, unchanged |
| Selected configuration | Release, net10.0 |
| Runtime | Runtime guard observed major 10; 10.0.12 was the only installed .NET 10 runtime |
| Test runtimeconfig | Microsoft.NETCore.App 10.0.0, rollForward Minor, concurrent/server GC enabled |
| Test framework and platform | Expecto 10.2.3 through YoloDev.Expecto.TestSdk 0.14.3, VSTest |
| Microsoft.NET.Test.Sdk | 17.12.0 |
| Paket | 10.3.1 |
| FSharp.Core | 10.1.201 |
| FSharp.Compiler.Service | 43.12.201 |

Package versions came from `paket.lock` and restored package metadata. They were not upgraded.
The project sets graph-based F# checking. No explicit LangVersion appeared in the inspected properties.
The script fixture requests `--langversion:preview`.
Inherited `DOTNET_GCDynamicAdaptationMode=1`, `DOTNET_ROLL_FORWARD_TO_PRERELEASE=1`, and `DOTNET_gcServer=1` remained unchanged.
No compiler or loader selector was set by the evaluation. Output confirms both compiler modes and Ionide WorkspaceLoader.

The local tool manifest restored Paket 10.3.1, ReportGenerator 5.5.4, Fantomas 7.0.5, fsharp-analyzers 0.37.2, and telplin 0.9.6.
This was a local-manifest restore, not a global tool installation.
Standard restore used existing user NuGet/tool caches. Cache writes were not isolated or removed.
All source, report, log, and build changes were confined to the clone, except this requested evaluation report.

## Commands and evidence

Commands below run from the clone root. `<clone>` denotes the isolated evaluation directory without disclosing a local account name.

```powershell
git clone https://github.com/ionide/FsAutoComplete.git <clone>
git -C <clone> checkout --detach 85886b187b87834e0fe0a410cb13332d7f9757ca
git rev-parse HEAD
dotnet --info
dotnet tool restore *> tool-restore.log

dotnet test test/FsAutoComplete.Tests.Lsp/FsAutoComplete.Tests.Lsp.fsproj -c Release -f net10.0 --filter 'FullyQualifiedName~script eviction' --logger 'console;verbosity=normal' --logger 'trx;LogFileName=fsautocomplete.trx' --results-directory evaluation-results *> focused-test.log

dotnet test test/FsAutoComplete.Tests.Lsp/FsAutoComplete.Tests.Lsp.fsproj -c Release -f net10.0 --no-build --no-restore --filter 'FullyQualifiedName~ScriptProjectOptionsCache|FullyQualifiedName~test host uses target runtime' --logger 'console;verbosity=normal' --logger 'trx;LogFileName=cache.trx' --results-directory evaluation-results -- Expecto.fail-on-focused-tests=true *> cache-test.log
```

Restore and both test commands completed with exit code 0.
The first test command restored and built the production projects, test project, and repository-defined prepared fixtures.
The second command used those existing outputs.

Completed active test names:

- `FSAC.general.test host uses target runtime` — passed, 3 ms.
- `FSAC.lsp.Ionide WorkspaceLoader.BackgroundCompiler.ScriptProjectOptionsCache.tests.reopening an unchanged script file should return same project options for file` — passed, 17 seconds.
- `FSAC.lsp.Ionide WorkspaceLoader.TransparentCompiler.ScriptProjectOptionsCache.tests.reopening an unchanged script file should return same project options for file` — passed, 10 seconds.

Both skipped names end with `script eviction tests.tests.can update script typechecking when arguments change`, once per compiler mode.

Raw evidence remains in the clone: `tool-restore.log`, `focused-test.log`, `cache-test.log`, and `evaluation-results/*.trx`.
Raw artifacts contain machine paths. This report omits account names and secrets.
Research artifacts are in `reliability/research/`: `system.md`, `properties.md`, `properties/duplicate-open.md`, `topology.md`, and `evaluation.md`.

## Production behavior and test topology

Source links use the exact target revision:

- [Script tests](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/test/FsAutoComplete.Tests.Lsp/ScriptTests.fs#L160): subscribes to the real `ScriptFileProjectOptions` event and calls `TextDocumentDidOpen` twice.
- [LSP handler](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/src/FsAutoComplete/LspServers/AdaptiveFSharpLspServer.fs#L714): forwards document data to `OpenDocument`.
- [OpenDocument](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/src/FsAutoComplete/LspServers/AdaptiveServerState.fs#L2623): returns immediately when the file is already open.
- [Options calculation](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/src/FsAutoComplete/LspServers/AdaptiveServerState.fs#L1520): selects the background or transparent FCS API and publishes the options event.
- [Real server fixture](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/test/FsAutoComplete.Tests.Lsp/Helpers.fs#L222): constructs `AdaptiveFSharpLspServer` and records client callbacks.

The test runs the real server and compiler in process. It uses real files and the actual project loader.
Initialize, Initialized, and a workspace-parsed notification establish readiness.
Awaited DidOpen calls and the nonzero event count demonstrate that the production path was reached.
The oracle asserts exactly one event. It does not use the adaptive map's equality operation.
The runtime `isFileOpen` check protects mutable state. It is not a permanent guarantee that a domain type could preserve.
No new synthetic workload was needed.

## Limits and triage

The cache test name promises more than the operations establish. No `DidClose` occurs, and no option values are compared.
The second open follows the already-open early return. This is duplicate-open coverage, not evidence of cache reuse after close.
Each test has a 60-second timeout and two fixed three-second waits. Later duplicate events remain possible outside this observation window.
The test does not verify diagnostics, edits, changed arguments, cancellation, concurrent opens, or controlled schedules.

The script uses unversioned `#r "nuget: Newtonsoft.Json"`. Network access or an existing dependency cache can affect repeatability.
The selected tests do not explicitly dispose the server. Process exit occurred, but asynchronous cleanup was not verified.
The fixture path is shared within the clone, with sequenced execution. A second concurrent run against that clone could interfere.
No wire transport, editor process, reverse proxy, container, or external server lifecycle was tested.
No claim is made for .NET 8, .NET 9, Linux, or macOS.

Classification: observed bounded pass for duplicate-open behavior; not exercised for argument-change invalidation; unsupported for true reopen and cleanup guarantees.
The smallest additional test would close the script, reopen it, and observe options and diagnostics with a completion signal.
That would be a different property and was not added during this evaluation.

## Skill findings

All four requested skills were applied at the specified skill revision.

| Skill | Observed value | Concrete limitation |
| --- | --- | --- |
| dotnet-reliability-research | Required source paths, reach conditions, oracle, bounds, and uncertainties. This narrowed an overstated test name. | No incorrect instruction demonstrated. |
| dotnet-library-documentation | Required resolved versions and authoritative adapter evidence. | Its primary-source table omits Expecto and YoloDev, despite its F# scope. Generic source guidance was sufficient. |
| dotnet-test-setup | Preserved the existing in-process fixture and exposed external package and cleanup limits. | It does not explicitly distinguish shared package/tool cache writes from project-local setup changes. |
| dotnet-test-triage | Prevented an all-skipped, exit-zero run from becoming a passing reliability claim. | No incorrect instruction demonstrated. |

Version-matched runner evidence: [YoloDev README at package commit df79056a899be54a80cd6fca9f77a8a8113e7d02](https://github.com/YoloDev/YoloDev.Expecto.TestSdk/blob/df79056a899be54a80cd6fca9f77a8a8113e7d02/README.md).
The restored package metadata identifies that commit. The README confirms VSTest integration and `Expecto.*` RunSettings after `--`.
Expecto 10.2.3 package metadata identifies source commit `160714e00ecf51035783f17ac9e822d2e6c2b3ba`.
Actual filtered test names and TRX counts confirm the selected filter worked.

Evaluator error: the initial filter was chosen before reading the full disabled test body.
Source inspection then identified `ptestList`, and the active scope was selected. This was not a defect in the skills.
No skill files were edited.

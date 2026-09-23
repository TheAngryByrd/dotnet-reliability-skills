# Minimal test topology

Date: 2026-09-23. Source revision: `85886b187b87834e0fe0a410cb13332d7f9757ca`.
No topology was started and no proposed test was executed.

## Stages

| Stage | Real components required | Controlled substitute | Fidelity limit |
| --- | --- | --- | --- |
| Pure transformations | Production functions, Expecto | Independent string/range/map oracle | Does not establish RPC, scheduling, FCS, or filesystem behavior. |
| Diagnostics and shared tasks | DiagnosticCollection and adaptive helpers | Controlled send callback, TaskCompletionSource barriers | Does not establish transport delivery or termination of compiler work. |
| Language server state | AdaptiveFSharpLspServer, real FCS, source-text factory, test client | Capturing in-process client | Does not test framed stdio, process exit, or editor edit application. |
| Project loading | Real Ionide.ProjInfo loader, MSBuild, SDK, temp projects and assets | Small generated project DAG | Does not represent all MSBuild tasks or arbitrary repository imports. |
| Scripts and dependencies | Real FCS and selected SDK/package restore | Dummy dependency manager only for API shape checks | Dummy success does not establish NuGet restoration, retries, or network failure recovery. |
| Formatting | Real Fantomas daemon for one integration leg | Existing injected formatting function for response-table tests | Controlled responses do not establish daemon discovery, cancellation, or child-process cleanup. |
| SourceLink | Real DLL/PDB metadata, real temporary filesystem, local HTTP stream server | Controlled local network endpoint | Does not establish public hosting, proxy, TLS, or service availability. |
| Test explorer | Real vstest.console and built sample test assemblies | Controlled slow/failing sample tests | AST-only discovery does not establish adapter execution or process termination. |
| Process and protocol | Built FSAC executable, pipes, real JSON-RPC frames | Small independent client and controlled child executable | In-process tests cannot substitute for this stage. |
| OS/runtime compatibility | Windows and Linux/macOS runners, net8.0/net9.0/net10.0 runtime legs | None for filesystem/casing claims | A Windows-only result does not establish other OS behavior. |

The minimum starting environment is local .NET plus temporary directories.
A local HTTP fixture is required for controlled SourceLink faults.
No database, message broker, cluster, or Aspire AppHost is justified by the inspected architecture.
Testcontainers is optional for a portable HTTP fixture. It is not needed for pure or in-process properties.

## Isolation and observation

The FCS filesystem shim is process-global. Tests also change current directories and environment variables.
Use separate processes or explicitly sequenced groups for these cases.
Use unique temporary roots for writes. Keep installed templates and SDK caches outside destructive test operations.
Record child process IDs and wait for confirmed exits before cleanup.

Subscribe before the triggering operation. Distinguish operation receipt, handler entry, effect completion, and acknowledgement.
Use unique diagnostic or symbol markers to distinguish fresh results from replayed events.
On timeout, retain logs and trigger observations. Classify the result as inconclusive unless a product contract and reached condition establish a violation.

No injected TimeProvider was found in the inspected timing paths.
A fake clock cannot control Async.Sleep, Task.Delay, filesystem timestamps, FCS, or external tools without an explicit seam.
Coyote needs a separate compatibility experiment for these F# Async, Task, adaptive-library, and external-process operations.

## Existing execution entry points

These commands were read from project guidance or CI. They were not run:

```powershell
dotnet tool restore
dotnet build -c Release
dotnet test -c Release -f net8.0 --no-restore --no-build --logger "console;verbosity=minimal" -- Expecto.fail-on-focused-tests=true
```

The LSP test project is an Expecto executable with Microsoft.NET.Test.Sdk and YoloDev.Expecto.TestSdk dependencies.
The separate TestExplorer project is an Expecto executable and builds sample projects in its post-build event.
A later execution task must verify the runner's actual filtering syntax before selecting a bounded property.
Use the existing framework and runners.

Record SDK, runtime, OS, compiler mode, loader, shard, dependency versions, seed, and timeout for every executed case.
Keep restore/build failures distinct from product property failures.

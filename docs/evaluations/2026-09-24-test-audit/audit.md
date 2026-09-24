# Read-only audit of executable examples

## Task and evidence boundary

Task: Audit all C# and F# executable checks in `dotnet-feature-workload/assets/examples` for test value, overlap, and runtime contract strength. Report retain, repair, consolidate, remove, or unresolved decisions. Do not run or change code.

Assigned source revision: `dd3efc7aea875260ef9f318990f1407dd96d8f0c`. This is the supplied snapshot identity. File hashes below identify the inspected bytes.

Applied skill: `dotnet-test-audit/SKILL.md`, including both references. Applied `simplified-technical-english` for report text. No memory or prior evaluation report supplied findings. No private research was inspected.

All findings use static reasoning. No builds, executable checks, discovery commands, or mutations ran. No runtime outcome was supplied. No source or configuration changed.

## Findings

### Repair: wait-timeout checks do not establish fake-time control

Locations: `dotnet-feature-workload/assets/examples/CSharp/Program.cs:34` and `dotnet-feature-workload/assets/examples/FSharp/Program.fs:36`.

Both checks request a one-second timeout through the fake provider. Both then permit five seconds of wall-clock time for that timeout.

A plausible defect removes the `clock` argument from the inner `WaitAsync`. The ordinary one-second timeout can still fault the wait within five seconds. The underlying completion source remains incomplete, so both assertions can still succeed.

The `wait.IsFaulted` condition is useful. It rejects a watchdog timeout while the inner wait remains pending. It does not establish which clock caused the inner timeout.

Retain the incomplete-operation assertion and subsequent `SetResult` plus awaited completion. Repair the clock-control proof if these checks claim virtual-time deadline coverage. Establish that the wait remains pending before its deadline, and distinguish virtual expiry from wall-clock expiry through an observed provider timer or verified synchronous expiry behavior.

Do not replace the five-second watchdog with a shorter timing threshold without assessing scheduling sensitivity. Provider callback guarantees need verification before selecting the repair.

This is a static counterexample to assertion strength, not an observed failing baseline or executed mutation.

### Repair: timer observations establish a coarse boundary

Locations: `dotnet-feature-workload/assets/examples/CSharp/Program.cs:26` and `dotnet-feature-workload/assets/examples/FSharp/Program.fs:27`. The stronger wording occurs at `dotnet-feature-workload/assets/examples/README.md:12`.

Both checks observe pending state at nine seconds and successful completion after advancing to ten seconds. A changed deadline of 9.5 seconds would satisfy those observations.

Retain both observations. If “exact timer boundary” is the intended contract, observe the timer immediately before the specified deadline at the supported timer resolution. Then advance the remaining interval and observe completion. Alternatively, describe the existing nine-to-ten-second observation precisely.

The real-time watchdog is useful for hangs. It is not itself evidence of exact virtual-time completion.

## Complete scope inventory

Every file under the requested example directory was inspected in full. Both complete programs, both project files, three MSBuild boundary files, and the README were inspected.

Additional inspected owners: `scripts/verify-examples.ps1`, `Makefile`, `.github/workflows/ci.yml`, `.github/workflows/ci-scripts-lint.yml`, root `AGENTS.md`, and the feature skill with its runtime reference.

There are two console entry points. There are no test-framework declarations, parameter-row registrations, conditional compilation branches, shared source files, or generated test registrations in the example files.

The inventory below counts five distinct behavioral checks per language. It splits pending and completion observations because they detect different failures. Entry-point completion and script checks are separate harness obligations.

All inventory rows have outcome **not run**. Static reach descriptions describe control flow, not observed execution.

| ID | Location | Contract and owner | Defect detected and reach evidence | Decision |
| --- | --- | --- | --- | --- |
| C1 | CSharp/Program.cs:12 | Local `Fits` accepts exact capacity | `Fits(3,7,10)` must return true. A strict comparison reaches exit 1 and the exact violation marker. | retain |
| F1 | FSharp/Program.fs:15 | Local `fits` accepts exact capacity | `fits 3 7 10` must return true. The mutant branch returns exit 1 with the same marker. | retain |
| C2 | CSharp/Program.cs:18 | Local `Fits` agrees with independent arithmetic | FsCheck compares subtraction against widened addition. Incorrect always-true, always-false, or threshold behavior can fail on generated inputs. | retain |
| F2 | FSharp/Program.fs:19 | Local `fits` agrees with independent arithmetic | Same oracle through F# union-pattern extraction and `Check.One`. Property execution follows the exact-capacity control. | retain |
| C3 | CSharp/Program.cs:29 | Provider-backed delay remains pending at nine seconds | `timer.IsCompleted` causes failure after the first advance. Detects sufficiently early completion. Timer creation precedes advance. | repair |
| F3 | FSharp/Program.fs:31 | Provider-backed delay remains pending at nine seconds | Same observation in an F# task expression. Does not detect a 9.5-second deadline. | repair |
| C4 | CSharp/Program.cs:32 | Delay succeeds after ten-second advance | Awaited timer exposes fault, cancellation, or persistent pending state through the watchdog. | retain |
| F4 | FSharp/Program.fs:34 | Delay succeeds after ten-second advance | `do!` observes completion and failures. The task is observed by `GetAwaiter().GetResult()`. | retain |
| C5 | CSharp/Program.cs:35 | Timeout faults the wait without completing its source | Catch requires `TimeoutException` and faulted inner wait. Incomplete source is checked, then completed and awaited successfully. Clock attribution remains weak. | repair |
| F5 | FSharp/Program.fs:37 | Timeout faults the wait without completing its source | Nested task returns timeout status. Outer task checks source state, completes it, and awaits it. Same clock-attribution gap. | repair |

The table locations beginning with CSharp or FSharp are relative to `dotnet-feature-workload/assets/examples/`.

Behavioral decision totals: six retain, four repair, zero consolidate, zero remove, zero unresolved. This does not include the separate unresolved runtime questions below.

| Harness obligation | Evidence | Decision |
| --- | --- | --- |
| C# asynchronous completion and failure propagation | `CSharp/Program.cs:10-57`: top-level awaits, success exit 0, explicit mutant exit 1, unexpected exception exit 2 | retain |
| F# asynchronous completion and failure propagation | `FSharp/Program.fs:14-57`: task workflow starts and is synchronously observed at line 52, with equivalent exit classes | retain |
| Compile both language consumers | Both projects use `OutputType=Exe`, `net8.0`, FsCheck 3.4.0, and TimeProvider.Testing 8.10.0. F# explicitly includes Program.fs. | retain |
| Build and baseline verification | `scripts/verify-examples.ps1:7-13`: Release build must succeed, then the built baseline must exit zero | retain |
| Intended defect verification | `scripts/verify-examples.ps1:15-20`: mutant must exit 1 and emit the exact marker | retain |
| Isolate inherited MSBuild settings | Three empty MSBuild files are present in the example directory. They establish local import boundaries. No support-code removal is proposed. | retain |

## Generated input and mutation limits

C2 and F2 request 100 generated tests each. Actual executed counts and distributions are unknown because execution was prohibited.

Both normalize `NonNegativeInt` inputs with modulo arithmetic. Used capacity is 0 through 100. Requested quantity is 0 through 200. Capacity is fixed at 100.

No property implication discards appear. FsCheck's actual generator and shrinker implementation was not inspected. Accepted counts, distribution, and shrink traces remain unknown.

The widened addition oracle differs from the subtraction implementation. The bounded inputs do not exercise arithmetic overflow. No overflow guarantee is claimed.

C# specifies replay values `123UL, 457UL`. F# uses the default seed. The README states this difference and expects failure replay information.

The runtime reference identifies FsCheck 3.4.0 replay-size behavior at `dotnet-feature-workload/references/runtime.md:19`. The external versioned source was not retrieved. Actual replay counts remain unresolved.

The deterministic exact-capacity check is independently useful. Generated cases do not guarantee that boundary. The mutant returns before generated properties or runtime checks execute.

Therefore, the current mutant demonstration establishes only the intended exact-capacity control path by static inspection. It cannot establish property-runner sensitivity, timer sensitivity, or timeout sensitivity.

## Overlap and retained contracts

Retain both language examples. Their semantic inputs overlap, but they compile and exercise different language-facing FsCheck APIs and asynchronous syntax.

C# uses `FsCheck.Fluent.Prop.ForAll` and replay configuration. F# uses `Check.One`, union-pattern extraction, task expressions, and an explicit entry point.

Neither language program proves that the other compiles or observes asynchronous completion correctly. Both share runtime dependencies, but that does not make either language consumer redundant.

Retain the exact-capacity check beside each generated property. Their failure-detection guarantees differ. The deterministic case guarantees one boundary. Generated cases explore additional bounded inputs.

Retain Linux and Windows execution routes. Native-process exit handling and runtime integration differ by platform. No assertion or support code has a proven redundant replacement.

No consolidate or remove decision is justified. There is no proposed deletion and no replacement validation claim.

## Execution and CI routing

Both projects are single-target `net8.0` console applications. They use a repository script, not VSTest, Microsoft.Testing.Platform, Expecto, or a framework test runner. Framework filter syntax does not apply.

The script selects both projects explicitly. It builds Release, runs baseline with `--no-build`, and runs the same build with `--mutant`.

Linux routing is `.github/workflows/ci.yml:19` → `make test` at line 39 → `Makefile:10` → verification script.

Windows routing is `.github/workflows/ci.yml:60` → `./scripts/verify-examples.ps1` at line 74.

Both jobs install SDK channel `8.0.x`. CI triggers include main pushes, listed pull-request events, and manual dispatch. No path filter restricts these example jobs.

Configured process executions total eight across both jobs: two languages × two modes × two operating systems. This is configuration evidence, not an execution count.

The script stops when a build, baseline, or mutant check fails. An earlier failure can prevent later projects from executing. The mutant path intentionally omits property and timer execution.

No outcome is classified as passed, failed, skipped, undiscovered, or filtered out. There was no execution or supplied run evidence. Local SDK and runtime versions were not queried.

## Unresolved evidence and proposed validation

- Dependency implementation contracts were not verified externally. In particular, callback completion timing and FsCheck replay-size behavior need version-matched evidence.
- Generated case counts, seeds for an actual F# run, distributions, and shrink behavior were not observed.
- No baseline or representative defect was executed. The runtime gaps above are static reasoning.
- No historical issue evidence was needed to recommend retaining the examples. No prior evaluation reports were read.
- No cancellation-token, disposal, serialization, persistence, or external-service contract is asserted by these examples. Such coverage is outside their stated API-example purpose.

When execution is separately authorized, use `pwsh -NoProfile -File scripts/verify-examples.ps1` on the unchanged source first.

For proposed timer repairs, use isolated copies to check a 9.5-second deadline and omission of the wait's provider. Keep each intended assertion and record baseline outcomes separately.

Run each language directly when a script failure prevents the other language from executing. Preserve Release, `net8.0`, package versions, and both operating-system routes.

These are proposed validation steps. They were not performed.

## Skill evaluation result

No demonstrated instruction defect was found in `dotnet-test-audit` during this evaluation.

The skill supported complete inventory, separate language and platform value, explicit reach evidence, and separation of static findings from runtime outcomes. Its runtime reference prompted the clock-attribution review.

The two repair findings concern example assertion strength. They are not evidence of a defect in the audit skill. This single read-only evaluation does not establish skill reliability for edits or runtime audits.

## Content identity

Skill SHA256 values:

```text
C918DF1592F992EF280CEB4653366EE44EB3CB7E52A5203E840FA54F16CAC2F4  dotnet-test-audit/SKILL.md
20F33AAD7546BCEA7961C3EFE10ED51CBD5D06FEFC6F2C4EB70A876D3AE82434  dotnet-test-audit/references/suite-audit.md
E28FF30CFC27981B6694E4A2A8BE17D8DED2AF0679AAB06F20EAFEAC36F35E9B  dotnet-test-audit/references/runtime-checks.md
```

Inspected source SHA256 values:

```text
E47556CD0EE9D1C69E6A870D4E098CC1692E15796F177F6729A33A841FB87D7F  AGENTS.md
B926655981FF2F7BD041AFE05340FE8F25C659CF2262EA825A3D39F15A95EB71  dotnet-feature-workload/assets/examples/README.md
44A3EECEE2978CAAB9E5E0AA1EFBA5444BE058462155B13E686C17D50DCCB265  dotnet-feature-workload/assets/examples/CSharp/Program.cs
A8DD0A1DA0708FEE5EDD324A27B49B5ED0824E75D843137F34754BF125D40C99  dotnet-feature-workload/assets/examples/FSharp/Program.fs
EAEEE5E620EE33469B5E2FE3DFE20D4A3FD555B58AB5E9870FEB7E77BD0F94B9  dotnet-feature-workload/assets/examples/CSharp/CSharp.csproj
F242F83EEA46178ADA7C200813FB4B7230492F4592CF9BAC1D1E37D9212C66F7  dotnet-feature-workload/assets/examples/FSharp/FSharp.fsproj
5C10E0DCA89D53FA828E2B8AD817F7DDECCB7775BEF36C1E75DBA0D87A103EE6  dotnet-feature-workload/assets/examples/Directory.Build.props
5C10E0DCA89D53FA828E2B8AD817F7DDECCB7775BEF36C1E75DBA0D87A103EE6  dotnet-feature-workload/assets/examples/Directory.Build.targets
5C10E0DCA89D53FA828E2B8AD817F7DDECCB7775BEF36C1E75DBA0D87A103EE6  dotnet-feature-workload/assets/examples/Directory.Packages.props
5F7FADD1DC52A48D8AA43E3DC45BC6801347FFC3E388E399E0EBBC4B30A376DC  scripts/verify-examples.ps1
30476A3CF17C9BA1F3E8B291A0A2AA5B2D45BD83E1CB8638E563C260331ED5B9  .github/workflows/ci.yml
CBB642080AE3E425DD00D83DD03CCCFAF934AD666DA2226D0C78ED8D560EA4B4  .github/workflows/ci-scripts-lint.yml
F06225289FC2D2501CF39A81916F8019EF548F9CDE5A3878D986DF94199BD37D  Makefile
FB4C585D7EED2EC82BCEA4F692416CB82F6370194F7816A290F74104FB6058FF  dotnet-feature-workload/SKILL.md
2871ECFEE1276773E2EDA90A7FA8A0746557061775077CB6F7A2A5290761ED8D  dotnet-feature-workload/references/runtime.md
```

## Exact inspection commands

The following commands only read files or calculate hashes. No command executes example code.

Initial skill reads:

```powershell
Get-Content C:/Users/jimmy/Repositories/public/TheAngryByrd/dotnet-reliability-skills/dotnet-test-audit/SKILL.md
Get-Content C:/Users/jimmy/.agents/skills/simplified-technical-english/SKILL.md
```

Working directory: isolated source snapshot root.

```powershell
rg --files -g AGENTS.md -g '*.cs' -g '*.fs' -g '*.csproj' -g '*.fsproj' -g '*.json' -g '*.yml' -g '*.yaml' -g '*.ps1' -g '*.props' -g '*.targets' -g '*.md'
```

Working directory: skill repository root.

```powershell
Get-Content dotnet-test-audit/references/suite-audit.md; Get-Content dotnet-test-audit/references/runtime-checks.md; Get-Content AGENTS.md
```

Working directory: isolated source snapshot root.

```powershell
$files = @('AGENTS.md','dotnet-feature-workload/assets/examples/CSharp/Program.cs','dotnet-feature-workload/assets/examples/FSharp/Program.fs','dotnet-feature-workload/assets/examples/CSharp/CSharp.csproj','dotnet-feature-workload/assets/examples/FSharp/FSharp.fsproj','dotnet-feature-workload/assets/examples/Directory.Build.props','dotnet-feature-workload/assets/examples/Directory.Build.targets','dotnet-feature-workload/assets/examples/Directory.Packages.props','dotnet-feature-workload/assets/examples/README.md','scripts/verify-examples.ps1'); foreach ($file in $files) { Write-Output $file; $line = 0; Get-Content $file | ForEach-Object { $line++; '{0}: {1}' -f $line, $_ } }; rg --files --hidden .github; rg --files --hidden dotnet-feature-workload/assets/examples
```

Working directory: isolated source snapshot root.

```powershell
$files = @('.github/workflows/ci.yml','.github/workflows/ci-scripts-lint.yml','Makefile','dotnet-feature-workload/SKILL.md','dotnet-feature-workload/references/runtime.md'); foreach ($file in $files) { Write-Output $file; $line = 0; Get-Content $file | ForEach-Object { $line++; '{0}: {1}' -f $line, $_ } }; rg -n --hidden 'verify-examples|make test|dotnet run|global.json|examples' .github scripts Makefile; Get-FileHash dotnet-feature-workload/assets/examples/CSharp/Program.cs,dotnet-feature-workload/assets/examples/FSharp/Program.fs,scripts/verify-examples.ps1 -Algorithm SHA256
```

Working directory: skill repository root.

```powershell
Get-FileHash dotnet-test-audit/SKILL.md,dotnet-test-audit/references/suite-audit.md,dotnet-test-audit/references/runtime-checks.md -Algorithm SHA256
```

Working directory: isolated source snapshot root.

```powershell
$files = @('AGENTS.md','dotnet-feature-workload/assets/examples/README.md','dotnet-feature-workload/assets/examples/CSharp/Program.cs','dotnet-feature-workload/assets/examples/FSharp/Program.fs','dotnet-feature-workload/assets/examples/CSharp/CSharp.csproj','dotnet-feature-workload/assets/examples/FSharp/FSharp.fsproj','dotnet-feature-workload/assets/examples/Directory.Build.props','dotnet-feature-workload/assets/examples/Directory.Build.targets','dotnet-feature-workload/assets/examples/Directory.Packages.props','scripts/verify-examples.ps1','.github/workflows/ci.yml','.github/workflows/ci-scripts-lint.yml','Makefile','dotnet-feature-workload/SKILL.md','dotnet-feature-workload/references/runtime.md'); foreach ($file in $files) { '{0}  {1}' -f (Get-FileHash $file -Algorithm SHA256).Hash, $file }; rg --files --hidden -g global.json -g AGENTS.md dotnet-feature-workload scripts .github
```

The final `rg` search returned exit 1 because it found no matching nested instruction or SDK-selection files in the searched directories. Hash calculation succeeded.

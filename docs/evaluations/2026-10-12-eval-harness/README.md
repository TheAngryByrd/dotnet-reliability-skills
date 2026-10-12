# Eval harness results: 2026-10-12

This evaluation is the first run of the [eval harness](../../../evals/README.md). It compares runs with and without `dotnet-mutation-testing` and `dotnet-review-inputs` on three agents.

## Setup

- Skill revision: `59afa0b5288cb396d38618dc7615539b027c97a7`. Six runs record the harness commit `86f10ad9e0b8ecbdaae88c81be59f335d2180bfb` instead: Codex `require-guards` baselines 3 and 4, and the four opencode `icedtasks-properties` runs. That commit does not change either skill.
- `require-guards`: FsToolkit.ErrorHandling at `d482e196cc3333e820355a0e412e01111944f3a7`, with one uncommitted test change and four mutant patches.
- `icedtasks-properties`: IcedTasks at `c51e9fc63fb0c78887f5c418b0530453a2b2cf80`.
- Targets: `claude:sonnet` (Claude Code 2.1.296), `codex` (Codex CLI 0.161.0, configured model `gpt-6-astra`), and `opencode:opencode/big-pickle` (opencode 1.18.10).
- Runs: 2 for each target, task, and mode. The Codex `require-guards` baseline had 4 attempts.
- Workspace SDK: .NET 10.0.401 on Windows 11, x64.
- Rubric judge: the default Claude Code `haiku` judge.
- Invocation: explicit. The with-skill prompt names `<skill>-eval`.

## Commands

Each agent ran in its own process with the same run ID. `DOTNET_ROOT` pointed to the machine-wide .NET installation.

```powershell
pwsh ./evals/run-evals.ps1 -RunId matrix1 -Skill dotnet-mutation-testing -Target claude:sonnet -Runs 2 -TimeoutMinutes 40
pwsh ./evals/run-evals.ps1 -RunId matrix1 -Skill dotnet-review-inputs -Target claude:sonnet -Runs 2 -TimeoutMinutes 30
```

The Codex and opencode processes used the same commands with `-Target codex` and `-Target opencode:opencode/big-pickle`. The extra Codex baseline attempts used this command:

```powershell
pwsh ./evals/run-evals.ps1 -RunId matrix1 -Skill dotnet-mutation-testing -Target codex -Task require-guards -Mode without -Runs 4 -TimeoutMinutes 40
```

All runs were then graded again, and the rubric agreement was measured:

```powershell
pwsh ./evals/grade-evals.ps1 -ResultDir <OutputRoot>/matrix1
pwsh ./evals/rubric-agreement.ps1 -ResultDir <OutputRoot>/matrix1 -Repeat 3
```

## Results

| Target | Task | Skill | Counted runs | Pass rate | Skipped | Seconds | Tokens | Cost (USD) | Turns | Failed builds | Failed test runs | Global copy |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| claude:sonnet | require-guards | with | 2 | 100% | 0 | 157 | 449,894 | 0.50 | 10.0 | 1.0 | 0.0 | 0 |
| claude:sonnet | require-guards | without | 2 | 85% | 0 | 258 | 532,364 | 0.26 | 10.5 | 1.0 | 0.0 | 0 |
| codex | require-guards | with | 2 | 100% | 0 | 525 | 1,187,815 | - | 27.5 | 1.0 | 1.0 | 0 |
| codex | require-guards | without | 0 | - | - | - | - | - | - | - | - | 4 |
| opencode:opencode/big-pickle | require-guards | with | 2 | 100% | 0 | 405 | 1,204,950 | - | 19.5 | 1.0 | 0.0 | 0 |
| opencode:opencode/big-pickle | require-guards | without | 2 | 55% | 0 | 1,405 | 1,622,747 | - | 29.5 | 0.5 | 3.0 | 0 |
| claude:sonnet | icedtasks-properties | with | 2 | 85% | 0 | 58 | 416,001 | 0.26 | 14.0 | 0.0 | 0.0 | 0 |
| claude:sonnet | icedtasks-properties | without | 2 | 84% | 1 | 56 | 386,772 | 0.15 | 10.5 | 0.0 | 0.0 | 0 |
| codex | icedtasks-properties | with | 2 | 95% | 0 | 153 | 392,531 | - | 18.0 | 0.0 | 0.0 | 0 |
| codex | icedtasks-properties | without | 2 | 100% | 0 | 155 | 529,212 | - | 13.5 | 0.0 | 0.0 | 0 |
| opencode:opencode/big-pickle | icedtasks-properties | with | 2 | 95% | 3 | 155 | 884,676 | - | 15.0 | 0.0 | 0.0 | 0 |
| opencode:opencode/big-pickle | icedtasks-properties | without | 2 | 80% | 0 | 188 | 1,211,754 | - | 19.0 | 0.0 | 0.0 | 0 |

Each with-skill run loaded `<skill>-eval`. No run had an agent error. Codex does not report cost. The pass rate is the mean of passed checks divided by judged checks in each run.

## Checks that differ between modes

`require-guards`, Claude checks that failed without the skill:

| Check | With skill | Without skill |
|---|---|---|
| M2 detected value matches the grader's test run | 2/2 | 1/2 |
| M3 detected value matches the grader's test run | 2/2 | 1/2 |
| failingTests lists only tests that failed in the grader's run | 2/2 | 1/2 |

M2 is detected only by the uncommitted test. M3 does not compile. The skill says to include uncommitted changes in the mutant snapshot and that a compiler error is an invalid mutant, not a detection. The Claude baselines missed these two facts.

The opencode `require-guards` baseline result comes from one run. The other baseline passed all 10 checks. One baseline timed out at 2,400 seconds and passed 1 of 10 checks. Its time and turns are in the opencode baseline means.

`icedtasks-properties` shows no consistent lift. Claude passed the `replay-limit` item in 0/2 runs with the skill and 1/2 runs without it. Codex passed every item in both modes, except `scheduling-only` in one with-skill run.

## Runs

Each row is one run after the final grade. A run name gives the target, task, mode, and run number.

| Run | Passed | Failed | Skipped | Seconds | Turns | Failed builds | Failed test runs | Skill loaded | Global copy | Timed out |
|---|---|---|---|---|---|---|---|---|---|---|
| `claude_sonnet-icedtasks-properties-with-r01` | 8 | 2 | 0 | 62 | 14 | 0 | 0 | yes | no | no |
| `claude_sonnet-icedtasks-properties-with-r02` | 9 | 1 | 0 | 54 | 14 | 0 | 0 | yes | no | no |
| `claude_sonnet-icedtasks-properties-without-r01` | 8 | 2 | 0 | 54 | 11 | 0 | 0 | no | no | no |
| `claude_sonnet-icedtasks-properties-without-r02` | 8 | 1 | 1 | 57 | 10 | 0 | 0 | no | no | no |
| `claude_sonnet-require-guards-with-r01` | 10 | 0 | 0 | 170 | 11 | 1 | 0 | yes | no | no |
| `claude_sonnet-require-guards-with-r02` | 10 | 0 | 0 | 143 | 9 | 1 | 0 | yes | no | no |
| `claude_sonnet-require-guards-without-r01` | 8 | 2 | 0 | 396 | 15 | 1 | 0 | no | no | no |
| `claude_sonnet-require-guards-without-r02` | 9 | 1 | 0 | 120 | 6 | 1 | 0 | no | no | no |
| `codex-icedtasks-properties-with-r01` | 9 | 1 | 0 | 158 | 12 | 0 | 0 | yes | no | no |
| `codex-icedtasks-properties-with-r02` | 10 | 0 | 0 | 147 | 24 | 0 | 0 | yes | no | no |
| `codex-icedtasks-properties-without-r01` | 10 | 0 | 0 | 160 | 13 | 0 | 0 | no | no | no |
| `codex-icedtasks-properties-without-r02` | 10 | 0 | 0 | 151 | 14 | 0 | 0 | no | no | no |
| `codex-require-guards-with-r01` | 10 | 0 | 0 | 304 | 24 | 1 | 2 | yes | no | no |
| `codex-require-guards-with-r02` | 10 | 0 | 0 | 745 | 31 | 1 | 0 | yes | no | no |
| `codex-require-guards-without-r01` | 10 | 0 | 0 | 222 | 18 | 1 | 0 | no | yes | no |
| `codex-require-guards-without-r02` | 10 | 0 | 0 | 241 | 17 | 1 | 0 | no | yes | no |
| `codex-require-guards-without-r03` | 10 | 0 | 0 | 232 | 18 | 1 | 0 | no | yes | no |
| `codex-require-guards-without-r04` | 10 | 0 | 0 | 268 | 21 | 1 | 0 | no | yes | no |
| `opencode_opencode_big-pickle-icedtasks-properties-with-r01` | 7 | 0 | 3 | 170 | 17 | 0 | 0 | yes | no | no |
| `opencode_opencode_big-pickle-icedtasks-properties-with-r02` | 9 | 1 | 0 | 140 | 13 | 0 | 0 | yes | no | no |
| `opencode_opencode_big-pickle-icedtasks-properties-without-r01` | 9 | 1 | 0 | 156 | 16 | 0 | 0 | no | no | no |
| `opencode_opencode_big-pickle-icedtasks-properties-without-r02` | 7 | 3 | 0 | 220 | 22 | 0 | 0 | no | no | no |
| `opencode_opencode_big-pickle-require-guards-with-r01` | 10 | 0 | 0 | 362 | 23 | 1 | 0 | yes | no | no |
| `opencode_opencode_big-pickle-require-guards-with-r02` | 10 | 0 | 0 | 448 | 16 | 1 | 0 | yes | no | no |
| `opencode_opencode_big-pickle-require-guards-without-r01` | 10 | 0 | 0 | 410 | 26 | 1 | 2 | no | no | no |
| `opencode_opencode_big-pickle-require-guards-without-r02` | 1 | 9 | 0 | 2400 | 33 | 0 | 4 | no | no | yes |

## Rubric agreement

`rubric-agreement.ps1` judged the 12 counted `icedtasks-properties` reviews three times. 69 of 72 items gave the same answer in all three grades (96%). No grade was missing a judge answer.

The three items that disagreed:

| Run | Item | Answers |
|---|---|---|
| Claude, without skill, run 2 | `evidence-kind` | yes/yes/no |
| Codex, with skill, run 1 | `scheduling-only` | no/no/yes |
| opencode, with skill, run 2 | `replay-limit` | yes/no/no |

## Interpretation

- `dotnet-mutation-testing` raised the pass rate for Claude (85% to 100%). The failed Claude baseline checks match facts that the skill states.
- The opencode `require-guards` difference (55% to 100%) comes from one timed-out baseline. The finished opencode baseline passed all checks, so this result does not show lift.
- `dotnet-review-inputs` showed no consistent improvement for Claude (84% without the skill, 85% with it) or Codex (100% without, 95% with). Both agents found the fixed-input and CI case-count limits without the skill. This task does not discriminate well for strong agents.
- Two runs per mode cannot establish a statistically reliable difference. Treat these results as a first sample.

## Limits

- The Codex `require-guards` baseline is not measurable on this machine. In all 4 attempts, Codex read `~/.agents/skills/dotnet-mutation-testing/SKILL.md` with `Get-Content`. The user's `~/.codex/AGENTS.md` names that skill. `skills.config` hides the skill from discovery, but it does not stop a direct file read. The harness detected each read (`globalSkillUsed`) and left these runs out. All 4 of these runs passed 10 of 10 checks after they read the skill.
- GitHub Copilot models in opencode returned a monthly quota error. The opencode runs use the free `opencode/big-pickle` model.
- One opencode `require-guards` baseline timed out at 40 minutes. It counts as a failed attempt.
- Two with-skill grades failed because of a grader defect that was fixed before the harness commit. `grade-evals.ps1` graded all runs again with the committed graders.
- Agents ran with the user's normal configuration, not `-Isolate`. User-level instruction files reached both modes.
- The rubric judge checks meaning with quoted evidence. A rubric item can still miss a correct statement that uses different terms.

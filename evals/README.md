# Skill evals

The eval harness measures whether a skill changes an agent's results. It runs each task with the skill and without it, then grades both results with the same grader.

Supported agents:

- Claude Code (`claude`)
- Codex CLI (`codex`)
- opencode (`opencode`)

## Prerequisites

- PowerShell 7.4 or later (`pwsh`) on Windows, Linux, or macOS.
- `git` and network access. Each task clones a pinned public repository.
- Each agent CLI that you test, on `PATH` and signed in.
- The SDK and runtimes that the task repository selects. The current tasks need a .NET 10 SDK and the .NET 9 runtime.
- For rubric checks, Claude Code (`claude`) signed in, or another judge command. See [Rubric judge](#rubric-judge).

> [!CAUTION]
> The runner starts agents without permission prompts: `--dangerously-skip-permissions`, `--sandbox danger-full-access`, and `--auto`. An agent can run any command as your user. Run evals only on a machine or container that you trust with that access.

## Run

```powershell
pwsh ./evals/run-evals.ps1 -Skill dotnet-mutation-testing -Target claude:sonnet,codex,opencode:opencode/big-pickle -Runs 2
```

This command runs each task of the skill on each target, with and without the skill, two times. It then writes `summary.md` and `results.json`.

| Parameter | Default | Meaning |
|---|---|---|
| `-Skill` | required | Skill name. The runner reads `<skill>/` at the repository root and `evals/<skill>/evals.json`. |
| `-Target` | `claude` | One or more `agent[:model]` values. The runner gives the model text to the agent's model option unchanged. |
| `-Task` | all | Task IDs from `evals.json`. |
| `-Mode` | `both` | `with`, `without`, or `both`. |
| `-Invocation` | `explicit` | `explicit` tells the agent to use the `<skill>-eval` skill. `implicit` tests whether the agent finds the skill from its description. |
| `-Runs` | `1` | Runs for each target, task, and mode. Use 2 or more before you compare results. |
| `-TimeoutMinutes` | `30` | Time limit for one agent run. The runner stops the process tree at the limit. |
| `-RunId` | timestamp | Name of the result folder. |
| `-Isolate` | off | Each run gets an empty home directory. See [Isolation](#isolation). |
| `-OutputRoot` | `<temp>/skill-evals` | Parent directory for results and caches. |
| `-DryRun` | off | Prints the agent commands and does not start agents. |

One runner process runs its agents one at a time. To run agents in parallel, start one process for each target with the same `-RunId`. Each run has a fixed folder name, and the summary reads every `run.json` under the result folder. A run that already has a `run.json` is skipped, so you can start the same command again after an interruption.

## Workspaces

Each run has its own folder `<OutputRoot>/<run-id>/<target>-<task>-<mode>-rNN/`:

- `ws/`: the agent's workspace. It is a clone of the task repository at the pinned commit, with `TASK.md` and the task input files.
- `transcript.jsonl` and `stderr.txt`: the agent's JSON event stream and error output.
- `grade/grading.json`: the grader's checks.
- `run.json`: the run's settings, metrics, and checks.

The runner keeps one full clone of each task repository under `<OutputRoot>/cache/repos/` and clones each workspace from it. The workspace is in the temp folder, not in this repository. MSBuild and `dotnet` read `Directory.*.props`, `Directory.Packages.props`, and `global.json` files from parent folders. A workspace inside a checkout can inherit settings that change the result. Each `run.json` records the SDK that `dotnet --version` selects in the workspace (`dotnetSdk`).

The runner adds `TASK.md`, the task input files, and the installed skill to `.git/info/exclude`. So `git status` in the workspace shows only the agent's changes.

## Isolation

For a run with the skill, the runner copies the skill to `ws/.claude/skills/<skill>-eval/` and `ws/.agents/skills/<skill>-eval/`. Claude Code reads the first folder, Codex reads the second, and opencode reads both. The runner changes the `name:` line to `<skill>-eval`. A global copy of the skill can be an older version, and the distinct name keeps it from standing in for the version under test.

The runner reads the `description` of each global skill and finds the skills that match the task's `contaminationKeywords` or the skill name. It hides these skills:

- Claude Code runs without the skill use `--disable-slash-commands`, which disables all skills. Claude Code runs with the skill can still load the global copies.
- Codex runs disable each matching skill outside `~/.claude/skills` with `-c skills.config=[{path='...',enabled=false}]`.
- opencode runs deny each matching skill by name through `OPENCODE_CONFIG_CONTENT`.

Each `run.json` records two values from the transcript:

- `skillUsed`: the agent loaded `<skill>-eval`.
- `globalSkillUsed`: the agent loaded a global copy named `<skill>`.

The summary does not count a with-skill run that did not load `<skill>-eval` (column `Not loaded`). It does not count a run in either mode that loaded a global copy (column `Global copy`). These runs compare the agent with itself.

Global instruction files, such as `~/.codex/AGENTS.md` or `~/.claude/CLAUDE.md`, still reach both modes. When such a file names the skill, a baseline agent can try to load it. The `globalSkillUsed` value shows when that happened.

The runner and the rubric judge remove the variables of a parent Claude Code session, such as `CLAUDECODE`, from the child environment. opencode runs use `--pure`, which disables external plugins.

With `-Isolate`, each run uses an empty home directory. The runner sets `HOME`, `USERPROFILE`, `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `CLAUDE_CONFIG_DIR`, and `CODEX_HOME` to that directory. Agents then cannot read your saved logins or global skills. Supply credentials as environment variables: `ANTHROPIC_API_KEY` or `CLAUDE_CODE_OAUTH_TOKEN` for Claude Code, `CODEX_API_KEY` for Codex, and the key of the opencode provider. Providers that need a saved login do not work with `-Isolate`.

## Skill use

The runner reads each transcript and records whether the agent loaded the skill:

- Claude Code: a successful `Skill` tool call with the skill name, or a successful tool result that contains the skill's `name:` frontmatter line.
- Codex: command output that contains the skill's `name:` frontmatter line.
- opencode: a completed `skill` tool call with the skill name, or completed tool output that contains the `name:` frontmatter line.

A message that only names the `SKILL.md` path is not evidence of a load.

## Effort metrics

A skill can show its value through fewer failed loops when the pass rate stays the same. Each `run.json` records these values:

| Value | Source |
|---|---|
| `seconds` | Wall-clock time of the agent process. |
| `inputTokens`, `outputTokens` | Claude Code: `usage` of the final `result` event, with cache tokens. Codex: sum of `turn.completed` usage. opencode: sum of `step_finish` tokens, with cache and reasoning tokens. |
| `costUsd` | Claude Code `total_cost_usd` and opencode step cost. Codex does not report cost. |
| `turns` | Claude Code: `num_turns`, or tool calls plus 1 for a stopped run. Codex: completed tool items plus 1. opencode: `step_finish` events. |
| `failedBuilds` | `dotnet` build, test, run, fsi, publish, pack, or msbuild calls with compiler or MSBuild errors (`error FS`, `error CS`, `error MSB`, `error NU`, `Build FAILED`), or a failed non-test call. |
| `failedTestRuns` | `dotnet test` calls that compiled and exited with an error. |
| `agentError` | An error that stopped the agent, for example a provider quota error, a Codex `turn.failed` event, or a non-zero exit code. The summary does not count these runs. A Codex `error` event that a `turn.completed` event follows is a retried stream error, not an agent error. |
| `timedOut` | The runner stopped the agent at `-TimeoutMinutes`. A timed-out run counts as a failed attempt, and the grader grades its workspace. |

The runner removes a `pwsh -Command` or `bash -lc` wrapper and ignores text in quotes. `dotnet` must then start a command. So `rg 'dotnet build'` is not a build call. Each agent counts turns in a different way. Compare turns between the modes of one target, not between agents.

A failed build or test run is not always a wasted loop. In `require-guards`, a correct agent builds one mutant that does not compile and runs tests that fail for two mutants. So a correct run usually has 1 failed build and up to 2 failed test runs in both modes. The exact count depends on how the agent combines its commands. Compare the modes, not the absolute values.

## Grade again

After you change a grader, grade an existing result folder again. The agents do not run again.

```powershell
pwsh ./evals/grade-evals.ps1 -ResultDir <OutputRoot>/<run-id>
```

Use `-Task` to grade only some tasks. The script reads the metrics from each `transcript.jsonl` again, then updates each `run.json`, `results.json`, and `summary.md`.

The mutation grader caches the outcome of each mutant by commit, patches, test arguments, and an outcome version. It does not cache an infrastructure failure, such as a restore error, an MSBuild error, or a test run that stopped without a failed test. The grader then throws. The runner records a skipped `Grader completed` check, so the run has no pass rate. `grade-evals.ps1` can grade the run again. Change the outcome version in the grader when the outcome rules change.

## Rubric judge

A rubric check judges prose, such as a review or a research catalog. A separate judge model answers yes/no questions about one document that the agent wrote. It must quote the document as evidence.

- The judge receives only the rubric questions and the document. It does not see the mode, the transcript, or the skill text. The function replaces the install name `<skill>-eval` with `<skill>` in the document.
- A `yes` answer passes only when its quote is part of one line of the document. The function collapses whitespace and straight quotes before it compares. A quote shorter than 4 characters, a quote on more than one line, or a quote that is not in the document makes the check skipped (`passed` is null).
- A `no` answer fails. It needs no quote, because the evidence for an absence is the document itself.
- The function skips all checks when the judge fails, when its output has no `items` array, or when `SKILL_EVAL_JUDGE` is not valid. A skipped check does not count as a pass or a failure.
- The function cuts the document at 60,000 characters.

The judge command comes from `SKILL_EVAL_JUDGE`, as a JSON array of the command and its arguments. The judge reads the prompt from stdin and writes JSON with the shape `{"items":[{"id":"...","answer":"yes","quote":"..."}]}`. Claude Code `--output-format json` output with `structured_output` also works. Set `SKILL_EVAL_JUDGE` to `off` to skip all rubric checks.

The default judge is Claude Code with the `haiku` model and a JSON schema. It runs in an empty temp folder with no tools, no skills, no setting sources, no MCP servers, and its own system prompt. Keep `--system-prompt` in a Claude Code judge command. Without it, the judge gets the normal system prompt and your instructions.

### Agreement

Judge the same saved documents several times and record how often each item gives the same result:

```powershell
pwsh ./evals/rubric-agreement.ps1 -ResultDir <OutputRoot>/<run-id> -Repeat 3
```

The script judges only runs that the summary counts and that wrote the rubric document. It compares the judge's raw `yes` or `no` answers, also when a quote check skipped a result. An item without a judge answer in a grade is not in the rate, and the script reports the number of these items. The script writes `rubric-agreement.json` in the result folder. Record the agreement rate with the results. Rewrite an item that does not agree before you use its results.

## Tests

The fast tests need only PowerShell. They use transcript fixtures and a fake judge:

```powershell
pwsh ./evals/tests/Metrics.Tests.ps1
pwsh ./evals/tests/Rubric.Tests.ps1
pwsh ./evals/tests/Grading.Tests.ps1
```

`make test-evals` runs the fast tests, and CI runs `make test-evals`.

Each task has a grader test that grades a known-good and a known-bad workspace. These tests clone the task repository. The mutation test builds it, and the review test calls the real judge:

```powershell
pwsh ./evals/dotnet-mutation-testing/tests/Grader.Tests.ps1
pwsh ./evals/dotnet-review-inputs/tests/Grader.Tests.ps1
```

CI does not run the grader tests, because they need network access, .NET 10, and a signed-in judge. Run them after you change a grader.

## Add a task

1. Select a pinned public repository from `docs/evaluations/`, or another public repository at a full commit SHA.
2. Create `evals/<skill>/evals.json`:

   ```json
   {
     "skill": "my-skill",
     "contaminationKeywords": ["words that identify a global skill on the same subject"],
     "tasks": [
       {
         "id": "short-task-id",
         "repository": { "url": "https://github.com/owner/repo.git", "commit": "<full SHA>" },
         "workingTreePatch": "inputs/optional-uncommitted-change.patch",
         "files": ["inputs/extra-file-or-folder"],
         "grader": "graders/short-task-id.ps1",
         "prompt": "The task text. Ask for an output file with a fixed shape.",
         "rubricDocument": "review.md",
         "rubric": [{ "id": "short-id", "question": "A yes/no question about the document." }]
       }
     ]
   }
   ```

   `workingTreePatch`, `files`, `rubricDocument`, and `rubric` are optional. A task without `repository` starts in an empty git repository.

3. Make the task depend on a skill fact. A task that a careful agent passes without the skill does not measure the skill.
4. Write the grader. It is a PowerShell script with this contract:

   ```powershell
   param(
       [Parameter(Mandatory)][string]$Workspace,  # the agent's ws/ folder
       [Parameter(Mandatory)][string]$OutDir      # write grading.json here
   )
   Import-Module (Join-Path $PSScriptRoot '../../lib/Grading.psm1') -Force
   $checks = @()
   $checks += New-Check 'Check text' $true 'evidence'
   $checks += New-Check 'Check that needs a tool' $null 'skipped: reason'
   $checks += Invoke-Rubric -Workspace $Workspace -EvalDir (Split-Path $PSScriptRoot) -TaskId 'short-task-id'
   Write-Checks (Join-Path $OutDir 'grading.json') $checks
   ```

   `passed` is `$true`, `$false`, or `$null` for a skipped check. Grade by running the agent's result when possible. Compute expected values by running code in the grader, not from constants that can drift. The summary pairs checks by text, so grade old results again after you change a check text.

5. Add `evals/<skill>/tests/Grader.Tests.ps1` with a known-good and a known-bad workspace. Run it before you trust the grader.
6. Run one baseline per target (`-Mode without -Runs 1`). If the baseline passes every check, change the task. Then freeze the prompt and inputs. A grader fix can be graded again, but a prompt change needs new runs.

Write rubric items with these rules:

- Make `yes` the good answer.
- Ask one question about one statement. Name the function, file, or value.
- Ask about something that one line of the document can show.
- Remove words that two readers can interpret in different ways.

## Tasks

| Skill | Task | Repository | What it checks |
|---|---|---|---|
| `dotnet-mutation-testing` | `require-guards` | FsToolkit.ErrorHandling `d482e196` | The workspace has an uncommitted test change. The agent reports whether existing tests detect four `Result.require*` mutants. The grader builds and tests each mutant on the same uncommitted tree. It compares each `detected` value and failing test name with its own run. It also checks that no mutant remains and that the uncommitted test change is unchanged. Then it builds and tests a copy of the whole final workspace. One mutant does not compile, and the skill says that a compiler error is not a detection. |
| `dotnet-review-inputs` | `icedtasks-properties` | IcedTasks `c51e9fc6` | The agent reviews the FsCheck properties and writes `review.md`. Code checks confirm that the repository is unchanged and that each `file:line` citation exists. Six rubric items check for the fixed-input `parallelism` properties, the fixed work sizes, the CI case count, scheduling as the only variation, the replay limit, and a statement of measured or inferred evidence. |

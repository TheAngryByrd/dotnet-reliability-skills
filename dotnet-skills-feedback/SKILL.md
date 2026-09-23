---
name: dotnet-skills-feedback
description: Prepare a reviewable GitHub bug report for the .NET reliability skills, including skill revision, agent details, runtime context, and observed failure. Does not submit the report automatically.
license: Apache-2.0
---

# Prepare skill feedback

Use the installed skill repository's configured issue destination. For this distribution, it is:

https://github.com/TheAngryByrd/dotnet-reliability-skills/issues/new?template=bug_report.yml

Verify the repository and template if working from a different fork.

## Prepare the report

Capture the active skill, installed revision, agent/version when available, user request, observed behavior, and expected behavior stated by the user.

Include relevant .NET SDK/runtime, target framework, source language, library version, runner, command, and minimal failure evidence.

Distinguish the agent's inference from the user's account. Do not invent an expected result or claim an environment detail was verified when it was not.

Inspect the issue template's field IDs before generating a URL. Percent-encode each value. Keep the URL below 2,000 characters and omit optional details if necessary.

If a useful report is longer, write a local Markdown draft and provide the issue link separately. Remove credentials and unrelated private source.

## Output

Present the draft or prefilled URL for user review. Do not submit the issue unless the user explicitly requests submission.

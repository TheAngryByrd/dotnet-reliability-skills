# Contributing

Add skills as `<skill-name>/SKILL.md` at the repository root. Keep references and assets inside each skill so individual installation works.

## Required checks

```sh
python scripts/validate-skills.py
pwsh -NoProfile -File scripts/verify-examples.ps1
```

`make validate` and `make test` provide the same checks. Python 3.11+ and PowerShell 7 are used in CI.

Use realistic tasks to review agent behavior. Structural validation cannot establish that instructions select the correct tool or interpret a failure correctly.

## Writing and compatibility

Write direct instructions. Include source-language, package-version, test-runner, and runtime limits where they affect decisions.

Keep C# and F# guidance equally explicit. Do not assume C# tool support implies F# source support.

Keep repository history and attribution in license notices rather than skill instructions. Preserve license files when distributing individual skills.

Do not add prose-matching tests. Verify machine-readable metadata, runnable examples, and observable behavior.

## Pull requests

Describe the behavior change and relevant evidence. Include limitations that affect use.

Use `changelog - breaking` for renamed or removed skills and `changelog - non-breaking` for additions and compatible fixes. Version and changelog automation runs after labeled PR merges. Do not edit `metadata.version` or `CHANGELOG.md` manually.

## Local development

On systems with symbolic-link support, `make install-dev` links skills into existing Codex and Claude directories. Do not run it unless you intend to change your installed skills.

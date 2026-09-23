# Repository guidelines

Add root-level skill directories with matching `name` frontmatter and a nonempty `description`. Each `SKILL.md` needs a top-level heading.

Keep each skill self-contained. References must remain usable when only that skill directory is installed.

Keep instructions focused on C#, F#, .NET libraries, and runtime contracts. Do not include repository history in operational instructions.

Preserve the target repository's SDK, package versions, language, test framework, and runner. Distinguish input replay from scheduling control.

Use existing checks:

- `python scripts/validate-skills.py` or `make validate` for structure.
- `pwsh -NoProfile -File scripts/verify-examples.ps1` or `make test` for C#/F# examples.
- `make validate-links` for Markdown links when lychee is available.
- `make validate-changelog` for changelog structure.

Run examples when changing their code, package references, or runtime instructions. Verify both passing execution and the intended defect detection.

Use behavioral evaluation that matches the requested scope for substantial skill changes. Do not assert natural-language wording in tests.

For repository-wide research, preserve that scope in evaluator assignments. Audit the subsystem inventory against projects, entry points, and state owners before accepting the result. A focused test run cannot establish repository-wide research coverage. Retain the full research artifacts and report incomplete inspection explicitly.

Preserve Apache-2.0 attribution in LICENSE and NOTICE files. Record material adaptation notices there rather than in skill instructions.

Use clear conventional commit messages. Do not manually edit skill version metadata or CHANGELOG.md. The existing merge automation manages both for labeled PRs.

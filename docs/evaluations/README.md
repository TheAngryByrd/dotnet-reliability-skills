# Repository evaluations

Repository evaluations test whether the skills select suitable methods and produce evidence against real code. They complement structural validation and the included API examples.

## Results

The [2026-09-23 evaluation](2026-09-23/README.md) covers Fantomas, IcedTasks, FsToolkit.ErrorHandling, and FsAutoComplete.

## Method

Use an isolated clone pinned to a full source commit. Preserve the target repository's SDK, package versions, language, test framework, and runner.

Give the evaluating agent a realistic request, the relevant skills, and the repository. Do not supply the expected conclusion or a suspected defect.

For research evaluation, preserve the user's research scope in the evaluator assignment. Record that assignment in the report.

Check the resulting subsystem inventory against the repository's projects, entry points, and state owners. Require source-backed inspection and property records across the major in-scope areas. Naming areas without inspecting them does not establish coverage.

Assess research breadth separately from executable test depth. Reject a focused test investigation as evidence of repository-wide research. Publish the full research artifacts and state any incomplete areas.

Apply only the skills needed for that request. Adding containers or randomized tests to every repository would not demonstrate correct selection.

Keep any generated tests and mutants in the evaluation copy. Do not change the user's checkout or publish changes to the evaluated repository.

## Required evidence

Each report records:

- Skill revision and repository revision.
- User-style request and skills applied.
- Selected production behavior and its observable contract.
- SDK/runtime, target framework, package and runner constraints.
- Exact commands, executed test scope, counts, and exit status.
- Generated workload or mutant patch when applicable.
- What passed, what failed, and what was not exercised.
- Any skill correction supported by the result.

A passing repository suite alone does not establish that the skill worked. Explain how the skill selected the property, oracle, environment, or failure interpretation.

For mutation evaluation, preserve the passing baseline, source patch, predicted violation, actual failure, and restored result. Compile errors do not count as detection.

For infrastructure blockers, record the failed phase and the exact prerequisite. Do not replace a repository's SDK or dependencies merely to obtain a passing result.

## Repeating an evaluation

Clone the recorded repository and check out its exact commit. Apply the supplied workload patch, if any, and use the reported command and toolchain.

Apply a mutant only in a separate disposable copy. Remove it before measuring the restored baseline.

Update the report when a skill correction changes the decision under test. Keep earlier results associated with the skill revision that produced them.

The recorded evaluations are bounded samples. They do not certify every library version, test platform, or infrastructure provider mentioned by the skills.

# Supported runtime and compiler-mode test selections exercise the intended suites

- Slug: `test-build-compatibility`
- Priority: **P2**
- Subsystem: build-support
- Outcome: **not exercised**
- Implementation status: Production mechanism exists. The proposed general property was not implemented or executed in this research.

## Claim and evidence

Supported runtime and compiler-mode test selections exercise the intended suites.

[test/FsAutoComplete.Tests.Lsp/Program.fs:75-145](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/test/FsAutoComplete.Tests.Lsp/Program.fs#L75-L145)

Test registration selects two compiler modes by default and optional shards 1-4. Project files target multiple runtimes and restore fixture projects before build.

## Preconditions and input domain

All declared runtime targets, both compiler modes, both workspace loader choices, valid/invalid shard values, and default selection.

## Boundary and invariant

Shard input is parsed with explicit alternatives and invalidArg for unsupported values. Environment variables still control mutable process-wide settings.

## Observable result and oracle

Compare listed test identities with an independent registration inventory. Ensure shard union equals the intended suite and each leg uses its selected runtime.

## Test method

Runner discovery and focused smoke tests after restore. Keep Expecto and existing project structure.

## Reach condition and observation bound

Bound discovery at 60 seconds after successful build. Confirm runtime identity and nonzero selected test count. These are proposed test deadlines, not product service-level guarantees.

## Fault model and expected failure

Unknown shard, missing runtime, failed fixture restore, or focused-test markers. Expected explicit failure instead of an empty successful suite.

## Existing test evidence

No direct test body is claimed.

No runtime or discovery execution occurred. Project and registration source were inspected. FSDN is not registered, and script eviction uses ptestList.

Existing test source is inspection evidence only. No test outcome was observed.

## Open questions and limits

Benchmarks are measurement tools, not correctness tests. DummyDependencyManager returns empty successful resolution and does not establish NuGet restore reliability.

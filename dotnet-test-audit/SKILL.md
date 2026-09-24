---
name: dotnet-test-audit
description: Audit C# and F# tests for meaningful regression detection, redundant coverage, and implementation coupling. Use for test reviews, proposed test additions, or scoped suite cleanup while preserving independently useful contracts.
license: Apache-2.0
---

# Audit .NET test value

Identify what each test can detect before recommending a change. Optimize confidence and maintenance cost, not test count or deleted lines.

For a review, produce findings without editing tests or production code. For authorized cleanup, establish evidence before changing each candidate.

## Establish the audit boundary

Read repository instructions, the requested scope, test projects, and CI selection. Preserve the existing language, SDK, dependencies, framework, and runner.

Identify the selected target frameworks and execution mechanism: VSTest, Microsoft.Testing.Platform, Expecto executable, or repository script. Do not assume their filter syntax is interchangeable.

For subsystem or repository-wide work, use the [suite inventory procedure](references/suite-audit.md). A sample can inform priorities but cannot complete a broader audit.

For each proposed addition or existing candidate, establish:

- The observable contract and the production entry point that owns it.
- A plausible defect and the assertion that would detect it.
- The inputs and observations that demonstrate execution of the relevant path.
- Any existing test that detects the same defect under the same conditions.
- The distinct value of this layer, such as serialization, runtime integration, failure handling, or lifecycle behavior.

An additional layer can be valuable even when it repeats inputs. Name the different failure it detects instead of enforcing one test per behavior.

## Inspect the evidence

Read the complete test, parameter data, helpers, production owner, and relevant callers. Inspect discovery and conditional compilation before treating a declaration as executed coverage.

Follow mocked behavior to the production boundary. Determine whether the fixture supplies the outcome that the implementation should produce.

Read dependency contracts when the assertion depends on provider or runtime behavior. Use [C# and F# checks](references/runtime-checks.md) for asynchronous code, generated inputs, and compiled boundaries.

Investigate these patterns, without treating them as automatic deletion rules:

| Pattern | Evidence to seek |
| --- | --- |
| No explicit assertion | An implicit contract, such as compilation, successful completion, or an exception that fails the runner |
| Expected value computed by production code | An independent specification, fixture, or distinct algorithm that can expose a shared defect |
| Source text, snapshot, or reflection assertion | A stable API, wire, generated-code, architecture, or packaging contract |
| Repeated tests | Equivalent failure detection, inputs, runtime, configuration, and execution in CI |
| Private helper or mock call assertion | A required externally observable result, ordering rule, or independently useful internal invariant |
| Test-only access or injection | Actual callers and the design purpose of the boundary, including supported testing or extension APIs |
| Negative assertion | A reached operation, a specific forbidden effect, and a valid positive control |
| Empty collection or default result | Evidence that setup reached the intended state and did not return before the relevant operation |

Keep tests that independently protect compatibility, security, persistence, interoperation, platform behavior, or documented defaults. Speed, age, mocks, and internal visibility alone do not determine value.

## Record a decision

Use `retain`, `repair`, `consolidate`, `remove`, or `unresolved`. Record the test location, contract, detectable defect, evidence, and execution status.

Before consolidation or removal, also record:

- The exact retained assertion and its CI path, or evidence that the tested contract is obsolete.
- Differences in data rows, target frameworks, platforms, serialization, and runtime behavior.
- The purpose and non-test consumers of any support code proposed for removal.
- Relevant history or issue evidence when needed to explain the test. Mark unavailable evidence instead of inventing its purpose.
- The proposed edit, risk, and focused validation command.

Keep uncertain candidates unresolved. A passing replacement is insufficient if it never reaches the failure that the removed test protected.

## Apply authorized changes

Limit a batch to a related set of contracts. Transfer useful assertions before removing their previous owner.

Change production access or abstractions only when cleanup authorization includes those changes. Search reflection, dependency injection, generated callers, and external API obligations before declaring code unused.

Do not remove `InternalsVisibleTo`, interfaces, clocks, or factories merely because tests use them. Preserve valid dependency boundaries and binary compatibility.

Preserve failing contract assertions. Diagnose baseline failures separately. A test audit does not authorize repairing unrelated product defects or redefining expected behavior.

## Validate the result

Keep source fixed during each build and run. Record the source revision or dirty patch, configuration, command, selected runtime, and actual outcomes.

Run affected tests before and after authorized edits. Include sibling tests and applicable target frameworks when their contract or shared fixture changes.

Check discovered and executed cases, including parameter rows. Report skipped, undiscovered, filtered-out, and blocked cases separately from passes.

For bug regressions, demonstrate failure on the defective source and success on the repair when both revisions are available. State any missing control.

For uncertain replacement strength, test a representative defect in an isolated copy when mutation execution is authorized. Keep the same meaningful assertion.

Use compatible Stryker.NET for supported source projects or isolated manual mutations. Do not infer F# mutation support from a C# test runner.

An invalid build, missing dependency, or unrelated timeout does not prove defect detection. Rebuild consumers of changed F# inline code before comparing results.

Run repository formatting and change checks. Verify moved tests remain included in project files and CI filters. Recheck the contract inventory after edits.

## Deliver the audit

Use the repository's evidence location, otherwise `reliability/test-audit/`. Include findings, decisions, retained contracts, validation evidence, and unresolved scope.

Distinguish static reasoning, observed execution, and mutation evidence. Report production changes separately from tests and test support.

Do not claim repository-wide completion from a focused suite. Do not publish findings, commit, or open a pull request without authorization.

---
name: dotnet-reliability-research
description: Analyze a C# or F# system and produce an evidence-backed catalog of reliability properties and suitable .NET test methods. Use before designing property tests, concurrency tests, or integration workloads.
license: Apache-2.0
---

# Research .NET reliability properties

Produce a system model, property catalog, per-property evidence, and a minimal test topology. Research does not authorize implementation or dependency changes.

## Establish research scope

Record the requested scope before selecting properties or executable checks. A repository-level request covers the repository's major subsystems unless the user limits it.

Keep research scope separate from execution scope. A small test budget, an available fixture, or a convenient passing test does not narrow research.

First map projects, entry points, state owners, and subsystem boundaries from source. Use that inventory to define the research coverage matrix.

For each subsystem, record source evidence, important contracts, existing test evidence, proposed properties, and unresolved questions. Include cross-subsystem state transitions.

Use explicit research states: inspected, partially inspected, not inspected, or excluded by the requested scope. Explain partial inspection and exclusions.

Do not mark repository-wide research complete while a major in-scope subsystem is only named or uninspected. Report incomplete research if a limit prevents inspection.

When delegating, preserve the requested research scope in the assignment. Do not replace it with a selected test task.

## Discover the system

Use supplied designs, incidents, and external references. Ask only for missing scope that changes the analysis.

Inspect project files, `global.json`, imported build properties, NuGet or Paket dependencies, and existing test commands. Record:

- C#/F# versions, target frameworks, runtime, OS, and deployment topology.
- State ownership, persistence boundaries, transactions, and serialization.
- `Task`, `ValueTask`, F# `Async`, actors, channels, locks, and native calls.
- Existing checks and the code paths they actually exercise.

Treat comments and incident reports as claims to investigate. Represent promised guarantees as properties, not established facts.

## Discover properties

Examine data integrity, concurrency, failure recovery, protocol contracts, resource bounds, security boundaries, distributed coordination, lifecycle, idempotency, and compatibility.

For each property, identify the input boundary and the type or runtime check that preserves its invariant. Trace construction, deserialization, and updates.

Use [property records and evaluation](references/properties.md) to record evidence and select a test method.

## Evaluate the catalog

Reconcile the catalog with the subsystem inventory before choosing a bounded execution sample. Check coverage balance, implementability, observability, and the fit between each property and its test method. Do not prefer concurrency testing for a pure function.

Look for vacuous checks, missing trigger observations, correlated checks that share one faulty oracle, and assumptions the chosen environment cannot exercise.

Separate a pure model from the real implementation. A model-only test does not establish production behavior.

## Output

Use the repository's documentation convention, otherwise `reliability/research/`:

- `system.md`: requested scope, architecture, state, external dependencies, and runtime constraints.
- `coverage.md`: subsystem inventory, inspection state, source and test evidence, catalog links, and exclusions.
- `properties.md`: prioritized catalog with implementation status and open questions.
- `properties/<slug>.md`: source evidence, proposed oracle, and unresolved assumptions.
- `topology.md`: required services and the fidelity lost by substitutions.
- `evaluation.md`: gaps, refinements, and unsupported claims.

Record the source revision, dirty state, SDK/runtime, external references, and date. For dirty source, retain a patch or file hashes that identify the analyzed content. Extend existing records when they remain valid.

Completion requires source-backed inspection of the major in-scope subsystems and a catalog that accounts for their important contracts. Check `coverage.md` against the discovered project and entry-point inventory. A single-property report cannot satisfy a repository-wide request.

Report research coverage and execution results separately. Preserve the full research artifacts with the evaluation, not only a test summary. Do not claim a property passes before executing it.

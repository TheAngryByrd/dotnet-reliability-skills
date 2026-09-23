---
name: dotnet-review-inputs
description: Review C# or F# randomized test generators and workloads for limits on state space exploration. Use for FsCheck, Hedgehog, and custom generators. Produces findings without changing code.
license: Apache-2.0
---

# Review .NET workload inputs

Review how generated inputs and operation sequences reach different system states. Keep assertion quality and system correctness outside this review.

## Workflow

1. Locate the generators, shrinkers, test configuration, and workload operations. Follow wrappers to the actual generator.
2. Read [the exploration checklist](references/exploration.md).
3. Identify the generator library and installed version from project files, central package files, or Paket files.
4. Trace action selection, data generation, initial state, concurrency, pacing, and state tracking.
5. Check which distributions change between cases, between runs, or never.
6. Report each limitation with a source location, excluded behavior, and domain assumptions.

For FsCheck, inspect size parameters, custom `Arbitrary` instances, filtering, labels, classification, and shrinkers. Distinguish exhausted generation from a passing property.

For Hedgehog, inspect ranges and composed generators. Integrated shrinking does not establish application-specific validity automatically.

For custom generators, identify the seed owner and the order of random draws. A fixed seed does not reproduce thread scheduling or external services.

## Findings

Group findings as high signal, worth considering, or observation. Explain the workload first so the user can correct the model.

Report strengths that affect the assessment, such as explicit boundary families or measured operation distributions. Do not suggest code edits unless requested.

Fixed inputs are appropriate for deterministic regressions. Do not classify a regression suite as a deficient randomized workload.

## Completion

Every finding identifies observable generator structure and a concrete region it excludes. Distinguish inferred limits from measured distributions.

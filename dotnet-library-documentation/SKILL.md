---
name: dotnet-library-documentation
description: Verify C# or F# testing-library APIs and .NET runtime behavior against the installed versions and authoritative documentation. Use for FsCheck, Hedgehog, Stryker.NET, Coyote, test runners, and runtime contract questions.
license: Apache-2.0
---

# Read version-matched .NET documentation

## Resolve the version

Inspect `global.json`, project targets, central package files, lock files, tool manifests, and Paket files. Distinguish requested package ranges from resolved versions.

Determine whether the question concerns a library API, compiler behavior, test runner, or runtime contract. These can have different versions.

## Retrieve evidence

Prefer official versioned documentation, release notes, and source at the applicable tag or commit. Use package XML documentation or a small compile probe for uncertain API shapes.

| Topic | Primary source |
| --- | --- |
| Runtime, BCL, C#, F# | [Microsoft Learn](https://learn.microsoft.com/dotnet/) and matching dotnet source |
| FsCheck | [Manual](https://fscheck.github.io/FsCheck/) and [source](https://github.com/fscheck/FsCheck) |
| Hedgehog | [Manual](https://hedgehogqa.github.io/fsharp-hedgehog/) and [source](https://github.com/hedgehogqa/fsharp-hedgehog) |
| Mutation tools | [Stryker.NET](https://stryker-mutator.io/docs/stryker-net/introduction/) |
| Controlled concurrency | [Coyote](https://microsoft.github.io/coyote/) |
| External dependencies | [Testcontainers](https://dotnet.testcontainers.org/) |
| Orchestration | [Aspire](https://aspire.dev/) |

Retrieve only the relevant pages. Do not assume that a site supports Markdown suffixes or `llms.txt`.

## Interpret contracts

Distinguish source-language support from test-runner support. A .NET tool does not necessarily support F# mutation, every target framework, or all async primitives.

Do not treat the latest README as proof of an older package's behavior. Verify FsCheck major-version APIs and framework adapter versions before giving examples.

For runtime semantics, distinguish documented guarantees from current implementation details. A fixed random seed does not imply deterministic scheduling.

## Output

State the version, applicable contract, evidence link, and unresolved limits. Cite the source used rather than a search result.

If the answer requires a package upgrade, describe that requirement. Documentation lookup alone does not authorize installation or migration.

# Property records and test selection

## Record format

Record a stable slug, claim, priority, source locations, preconditions, input domain, observable result, oracle, and test method.

Also record the observation bound, reach condition, fault model, expected failure, existing coverage, implementation status, and open questions.

Use explicit outcomes: observed pass, observed violation, not exercised, inconclusive, or unsupported. A timeout is not automatically a product defect.

## Test methods

| Property | First suitable method | Limit |
| --- | --- | --- |
| Pure transformation or parsing | Existing test framework plus FsCheck or Hedgehog | Preserve valid values through generation and shrinking |
| Stateful API sequence | Generated commands, independent model, real implementation | Sequential commands do not test concurrent interleavings |
| Async cancellation or deadlines | Controlled signals and injected `TimeProvider` | Fake time controls only consumers of that provider |
| Task concurrency | Explicit barriers, then Coyote if compatible | Coyote controls supported rewritten operations, not all .NET execution |
| Persistence or protocol behavior | Real dependency through Testcontainers or an existing local environment | In-memory substitutes do not establish durable recovery |
| Multi-service lifecycle | Existing Aspire AppHost or focused container setup | Orchestration does not provide deterministic scheduling |
| Test sensitivity to defects | Stryker.NET where supported, otherwise isolated source mutants | A mutation score does not establish all properties |

Keep the repository's existing test framework. FsCheck and Hedgehog are property-testing libraries, not reasons to migrate the runner.

## Runtime questions

- Does cancellation request stopping, or does the operation actually terminate and release resources?
- Does a timeout stop only the wait while the underlying task continues?
- Is an F# `Async` workflow started once or multiple times? Where are its exceptions and cancellation observed?
- Can a `ValueTask` be consumed more than once? Check the producer contract rather than assuming `Task` semantics.
- Is the assertion about one operation, all operations, or eventual progress after a specific trigger?
- Does retry repeat a non-idempotent side effect after an ambiguous response?
- Does disposal require asynchronous cleanup? Who awaits it?
- Can checked arithmetic, structural equality, culture, or serialization alter the oracle?

A liveness claim needs a trigger, applicable environment assumptions, and a bound. One successful occurrence does not prove every request eventually completes.

References: [FsCheck](https://fscheck.github.io/FsCheck/), [Hedgehog](https://hedgehogqa.github.io/fsharp-hedgehog/), [Coyote](https://microsoft.github.io/coyote/), [Testcontainers](https://dotnet.testcontainers.org/), [TimeProvider](https://learn.microsoft.com/dotnet/standard/datetime/timeprovider-overview).

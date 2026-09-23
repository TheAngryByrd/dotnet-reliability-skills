# Exploration checklist

| Area | Evidence to inspect | Behavior that can be missed |
| --- | --- | --- |
| Action participation | Every operation always enabled, especially create/delete pairs | Accumulated state, repeated deletion, long periods without cleanup |
| Action weights | Fixed uniform distribution in every case | Write-heavy, read-heavy, or asymmetric client behavior |
| Ordering | A fixed create/use/delete sequence unrelated to real preconditions | Repeated operations, missing-resource handling, alternate legal sequences |
| Input bounds | Arbitrary small ranges instead of type and configured limits | Overflow, capacity transitions, empty and maximum values |
| Recursive data | Size consumed by every branch without a depth strategy | Deep acyclic structures and skewed trees |
| Filtering | Many rejected values or property preconditions rarely satisfied | Generator exhaustion and vacuous success |
| Shrinking | Shrinkers emit invalid domain values or destroy operation dependencies | A smaller failure caused by a different contract violation |
| Data shape | Fixed collection sizes, ASCII-only strings, all fields populated | Unicode, missing values, large payloads, sparse and nested structures |
| Identity | Only fresh keys, or a fixed tiny key pool | Collisions, duplicate delivery, contention, cardinality transitions |
| Initial state | Always empty or identical seed data | Recovery, migration, compaction, partially completed work |
| Concurrency | One fixed worker count | Sequential behavior, two-worker races, contention |
| Timing | Constant request rate and production-scale deadlines | Bursts, quiet periods, expiry, retry boundaries |
| Composition | Clients use disjoint state or identical strategies | Shared-resource conflicts and asymmetric progress |
| State tracking | Operations fire without tracking attempts and acknowledgments | Meaningful dependent sequences and ambiguous outcomes |

Vary policy between runs where it helps exploration. Keep explicit deterministic cases for important known boundaries.

Use a generator for valid domain values and a separate generator for invalid transport input. Do not bypass private constructors to expand the valid domain.

Inspect .NET distinctions: `null` versus empty, F# `None` versus `Some`, UTF-16 code units versus Unicode scalars, integer width, and checked arithmetic.

Include culture, timezone, and serialization variation only when they affect the contract. `DateTimeOffset` records an offset, not a timezone rule set.

References: [FsCheck](https://fscheck.github.io/FsCheck/), [Hedgehog](https://hedgehogqa.github.io/fsharp-hedgehog/).

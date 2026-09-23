# Canceling one shared task reference preserves other active consumers

- Slug: `shared-task-lifetime`
- Priority: **P1**
- Subsystem: concurrency
- Outcome: **not exercised**
- Implementation status: Production mechanism exists. The proposed general property was not implemented or executed in this research.

## Claim and evidence

Canceling one shared task reference preserves other active consumers.

[src/FsAutoComplete.Core/AdaptiveExtensions.fs:367-443](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/src/FsAutoComplete.Core/AdaptiveExtensions.fs#L367-L443)

RefCountingTaskCreator caches a real Task under a lock. Removing the last reference cancels and clears its token and cache.

## Preconditions and input domain

Two or more consumers with distinct AdaptiveCancellableTask wrappers. Generate acquire, read Task, cancel, complete, and reacquire.

## Boundary and invariant

Reference counts are mutable integers, guarded by locks. Cancel calls the supplied release action on every invocation.

## Observable result and oracle

Count producer starts and token cancellation events. Surviving consumers must receive the producer result. Last release must cancel once.

## Test method

Barrier-controlled Expecto tests first. Assess Coyote compatibility only after identifying supported rewritten operations.

## Reach condition and observation bound

One second after a controlled release or producer completion. Require two live references before canceling one. These are proposed test deadlines, not product service-level guarantees.

## Fault model and expected failure

Repeated Cancel, cancel-before-Task, faulted producer, and reacquisition. Failure includes early shared cancellation or negative reference accounting.

## Existing test evidence

No direct test body is claimed.

No direct RefCountingTaskCreator or AsyncAVal tests were found in the inspected test search. Server tests exercise these paths indirectly.

Existing test source is inspection evidence only. No test outcome was observed.

## Open questions and limits

Is repeated Cancel supported? No idempotent release type is visible here. The property must specify ownership before asserting repeated-release behavior.

# Compiler caches and script options follow the selected source and environment

- Slug: `compiler-script-cache`
- Priority: **P1**
- Subsystem: compiler
- Outcome: **not exercised**
- Implementation status: Production mechanism exists. The proposed general property was not implemented or executed in this research.

## Claim and evidence

Compiler caches and script options follow the selected source and environment.

[src/FsAutoComplete.Core/CompilerServiceInterface.fs:416-441](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/src/FsAutoComplete.Core/CompilerServiceInterface.fs#L416-L441)

Script option resolution uses a semaphore. ClearCaches disposes and recreates the bounded memory cache, then invalidates FCS state. Successful checks optionally cache weak references.

## Preconditions and input domain

Scripts with changed #r/#load directives, FSI options, SDK selection, repeated opens, cache pressure, and both compiler modes.

## Boundary and invariant

CompilerProjectOption is a DU. Cache keys use local paths and store weak references. Source/config coherence still depends on runtime invalidation.

## Observable result and oracle

Compare real checker results against a fresh checker for the same input/environment. Track option events and semantic results separately.

## Test method

Stateful Expecto integration, with controlled concurrent clear/check operations. Keep real FCS and real restore for package claims.

## Reach condition and observation bound

15 seconds after a configuration or source change. Require a semantic difference that depends on the changed option. These are proposed test deadlines, not product service-level guarantees.

## Fault model and expected failure

Restore failure, canceled waiter, cache eviction, and concurrent cache clearing. Failure is stale result reuse or inability to check subsequent scripts.

## Existing test evidence

[test/FsAutoComplete.Tests.Lsp/ScriptTests.fs:183-196](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/test/FsAutoComplete.Tests.Lsp/ScriptTests.fs#L183-L196)

The cache test sends two opens separated by sleeps and asserts one options event. It does not close the document or prove invalidation after changed options.

Existing test source is inspection evidence only. No test outcome was observed.

## Open questions and limits

Test cancellation while waiting for scriptLocker and release accounting. Cache size bounds entry count, not total FCS memory.

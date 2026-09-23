# Prioritized reliability properties

Source revision: `85886b187b87834e0fe0a410cb13332d7f9757ca`. Date: 2026-09-23.

The catalog has 31 proposed properties across 19 areas.
Priority ranks user impact and boundary risk, not a measured failure probability.
P0 addresses wrong edits, persistent corruption, stale diagnostics, and blocked required progress.
P1 addresses state consistency, recovery, process boundaries, and core feature contracts.
P2 addresses narrower compatibility, presentation, and supporting operations.

**All outcomes are not exercised.** Production mechanisms exist, but no proposed general property was implemented here.
Existing test bodies supply evidence of intended behavior. They do not supply an observed pass for this revision.

| Priority | Property | Suitable first method |
| --- | --- | --- |
| P0 | [Document changes preserve the latest accepted text and version](properties/document-change-consistency.md) | Generated command sequences against the real in-process server. Use plain offset arithmetic for the model. |
| P0 | [Older diagnostics cannot replace newer diagnostics from the same source](properties/diagnostic-version-order.md) | Expecto with generated state-machine commands, then barrier-controlled overlapping writers. |
| P0 | [A failed diagnostic send resolves waiters and permits later updates](properties/diagnostic-send-recovery.md) | Expecto with TaskCompletionSource barriers and injected send callback. Exercise the production DiagnosticCollection. |
| P0 | [Cancellation terminates the acknowledged wait without invoking pre-canceled work](properties/acknowledged-cancellation.md) | Expecto with explicit barriers and continuation capture. Test real helper, not a copied model. |
| P0 | [A saved dependency changes diagnostics in dependent files and projects](properties/dependency-recheck.md) | Existing Expecto integration fixtures plus generated save sequences. Use real FCS and project loaders. |
| P0 | [Rename edits change only the selected symbol in readable documents](properties/rename-edit-safety.md) | Generated small F# programs with real server rename. Preserve exact fixture assertions for difficult compiler cases. |
| P0 | [SourceLink cache paths stay contained and incomplete downloads are not reused](properties/sourcelink-cache-safety.md) | Real temporary filesystem and local HTTP server with controlled streaming. Use generated path cases through the production fetch entry point. |
| P0 | [Project edits preserve compile order and unrelated project content](properties/project-edit-integrity.md) | Generated operation sequences against temporary real files. Add controlled filesystem failure cases. |
| P1 | [Canceling one shared task reference preserves other active consumers](properties/shared-task-lifetime.md) | Barrier-controlled Expecto tests first. Assess Coyote compatibility only after identifying supported rewritten operations. |
| P1 | [Project snapshots invalidate the changed dependency closure](properties/snapshot-invalidation.md) | Generated DAG fixtures with real snapshot construction and file watchers. Keep graph-model checks separate from actual snapshot checks. |
| P1 | [Closing a document releases open state and clears diagnostics when required](properties/document-close-cleanup.md) | Generated server command sequences with real temporary directories. Add a repeated lifecycle test with measured resource counts. |
| P1 | [Valid UTF-16 text ranges preserve all text outside the replaced range](properties/source-text-ranges.md) | Expecto plus FsCheck or Hedgehog generators with validity-preserving shrinking. |
| P1 | [Applicable code fixes produce valid localized edits and remove their target diagnostic](properties/code-fix-correctness.md) | Keep Expecto code-fix fixtures. Add generated syntax families and isolated source mutants for diagnostic gates and insertion boundaries. |
| P1 | [Completion retries use changed text when the trigger arrives before its change](properties/completion-freshness.md) | Expecto integration with controlled change ordering. Avoid sleep-only scheduling. |
| P1 | [Semantic token encoding preserves ordered positions without unsigned underflow](properties/semantic-token-encoding.md) | Pure Expecto property tests. Generate ordered ranges directly and preserve order during shrinking. |
| P1 | [Only complete successful formatter responses produce edits](properties/formatting-result-contract.md) | Expecto component tests using existing injected formatting functions, plus one real Fantomas integration fixture. |
| P1 | [Analyzer selection and completion preserve document identity and server progress](properties/analyzer-isolation.md) | Existing Expecto integration with the OptionAnalyzer assembly. Add a controlled throwing and blocking analyzer fixture. |
| P1 | [Project command arguments preserve user values and child processes terminate](properties/dotnet-command-boundaries.md) | Process integration tests, plus parser examples. Use real dotnet for compatibility claims. |
| P1 | [Test discovery and execution preserve identities, filters, and terminal outcomes](properties/test-explorer-results.md) | Existing Expecto VSTest integration and a controlled long-running test assembly. Keep static AST discovery tests separate. |
| P1 | [Protocol failures remain isolated and shutdown releases the server process](properties/protocol-lifecycle.md) | Out-of-process protocol integration with pipes. In-process handler calls cannot establish framing or process behavior. |
| P1 | [Compiler caches and script options follow the selected source and environment](properties/compiler-script-cache.md) | Stateful Expecto integration, with controlled concurrent clear/check operations. Keep real FCS and real restore for package claims. |
| P1 | [Symbol queries return the correct identities and current source ranges](properties/symbol-query-consistency.md) | Generated small programs plus existing Expecto examples. Use real FCS to establish implementation behavior. |
| P1 | [Document URI conversion preserves identity across working-directory changes](properties/uri-identity.md) | Pure generated path cases on Windows and Linux, plus server open/navigation scenarios. |
| P1 | [Workspace loading refreshes project options and selects a containing project deterministically](properties/workspace-loading-selection.md) | Real-loader Expecto integration plus pure selection permutations. Drive the server workspaceLoad path for production invalidation. |
| P1 | [Configuration updates preserve the chosen omission policy and invalidate dependent state](properties/configuration-transition.md) | Pure conversion tests plus stateful Expecto server sequences. Use fresh diagnostics subscriptions and explicit input versions. |
| P2 | [Signature and inlay hints reference valid source positions and parameters](properties/signature-hint-bounds.md) | Generated syntax examples through real FCS and server. Use pure tests for truncation. |
| P2 | [External navigation selects an existing implementation assembly and valid location](properties/decompiler-fallback.md) | Temporary filesystem examples plus real assembly/PDB integration for decompilation and symbol location. |
| P2 | [Documentation rendering terminates and produces valid links or readable fallback text](properties/documentation-rendering.md) | Pure Expecto examples and generated markup. Run adversarial recursion cases in a process with a deadline. |
| P2 | [Logging and disabled tracing do not alter protocol output or request outcomes](properties/logging-noninterference.md) | Process integration for stdout isolation, component examples for null Activity handling. |
| P2 | [Remote search errors do not corrupt later language-server requests](properties/remote-search-failure.md) | Local HTTP contract integration requires an endpoint seam. A separate optional live smoke test checks the actual service. |
| P2 | [Supported runtime and compiler-mode test selections exercise the intended suites](properties/test-build-compatibility.md) | Runner discovery and focused smoke tests after restore. Keep Expecto and existing project structure. |


## Initial implementation order

1. Add independent pure oracles for source ranges, semantic-token encoding, and formatter response mapping.
2. Exercise production diagnostic collection ordering, failure recovery, and notification cancellation with explicit barriers.
3. Add distinct invalid-to-valid markers for dependency rechecks and snapshot invalidation.
4. Test SourceLink interrupted writes and canonical containment in disposable directories.
5. Exercise project XML edits, argv preservation, process output, and shutdown in child processes.
6. Expand semantic generated programs, code-fix variants, and runtime/OS compatibility.

Pure tests stay in Expecto. FsCheck or Hedgehog can supply generation and shrinking.
Neither library requires a runner migration. No dependency installation is authorized by this report.
Concurrency control is proposed only for stateful mechanisms. Pure transformations do not need Coyote.

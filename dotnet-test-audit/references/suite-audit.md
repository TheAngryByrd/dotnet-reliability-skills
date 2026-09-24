# Audit a complete test surface

Use this procedure when the request covers a subsystem or repository. Keep review scope separate from permission to edit or run infrastructure.

## Build the inventory

Map production projects, entry points, state owners, and test projects before selecting candidates. Include tests in shared projects, scripts, generated registrations, and integration harnesses.

Record each suite's target frameworks, platform conditions, runner, data sources, and CI selection. Compare declarations with discovered cases where execution is available.

Read parameter data in full. One declaration can represent different contracts across rows. Record separate decisions when rows differ.

Track `inspected`, `partly inspected`, and `not inspected` areas. Keep source inspection separate from runtime outcomes.

Do not reduce the inventory to convenient projects or runnable tests. Preserve blocked areas with their missing prerequisites.

## Establish coverage ownership

For each declaration or distinct data row, record:

| Field | Required evidence |
| --- | --- |
| Identity | File, test name, and applicable row or configuration |
| Contract | Observable guarantee and production owner |
| Sensitivity | Plausible defect and detecting assertion |
| Reach | Setup and observations that reach the behavior |
| Decision | Retain, repair, consolidate, remove, or unresolved |
| Replacement | Exact remaining proof for any proposed removal |
| Outcome | Not run, passed, failed, skipped, undiscovered, or blocked |

Audit overlapping layers by failure mode. A unit test can cover boundary cases that an integration test never supplies. Integration tests can cover wiring that unit tests bypass.

If discovery is delegated, assign complete owner boundaries and one writer for shared evidence. Require explicit uninspected areas in each returned report.

## Preserve contracts during cleanup

For authorized changes, group edits by contract ownership. Update the destination assertion and its registration before removing previous proof.

Keep baseline failures distinct from cleanup effects. A failure without an established cause is not evidence that a test is obsolete.

Review the removed assertions against their replacements. Check negative controls, parameter rows, supported runtimes, and generated or compile-only consumers.

Use an independent preservation review for large removals when available. Any missing contract remains unresolved until restored or shown obsolete with evidence.

When mutation checks are authorized, select plausible defects for the highest-risk transfers. Establish an executed baseline and isolate each mutation.

Record the changed source, selected tests, executed path, and intended assertion failure. Restore source and verify its identity afterward.

Do not require production fixes merely to finish an audit. Record product defects separately unless their repair is authorized.

## Reconcile the final scope

If the source revision changes, review affected inventory entries and new tests again. Do not preserve a deletion automatically during conflict resolution.

Record discovered, inspected, changed, and uninspected counts with explicit counting units. Test declarations, generated cases, and framework runs are different units.

List remaining proof per changed contract, validation outcomes, baseline failures, and execution limits. Report incomplete work instead of claiming complete coverage.

Line-count changes can describe maintenance cost. They cannot establish preserved behavior or justify a removal.

# Logging and disabled tracing do not alter protocol output or request outcomes

- Slug: `logging-noninterference`
- Priority: **P2**
- Subsystem: logging
- Outcome: **not exercised**
- Implementation status: Production mechanism exists. The proposed general property was not implemented or executed in this research.

## Claim and evidence

Logging and disabled tracing do not alter protocol output or request outcomes.

[src/FsAutoComplete/Parser.fs:242-304](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/src/FsAutoComplete/Parser.fs#L242-L304)

Console logging is routed to stderr and flushed in finally. Activity exception helpers guard null spans at FsOpenTelemetry.fs lines 569-615.

## Preconditions and input domain

Verbose logs, file logging, no ActivityListener, listener enabled, and unavailable exporter.

## Boundary and invariant

Optional tracing is represented by nullable Activity values with runtime guards. Log configuration controls stream routing.

## Observable result and oracle

Parse stdout as protocol frames only. Compare semantic responses with tracing enabled/disabled and inspect stderr independently.

## Test method

Process integration for stdout isolation, component examples for null Activity handling.

## Reach condition and observation bound

Five seconds after a completed request and shutdown. Require a generated log event during a real request. These are proposed test deadlines, not product service-level guarantees.

## Fault model and expected failure

Invalid log path and exporter failure. Startup rejection is distinct from corruption of an established protocol session.

## Existing test evidence

No direct test body is claimed.

No dedicated logging tests were identified in the inspected test inventory.

Existing test source is inspection evidence only. No test outcome was observed.

## Open questions and limits

Large request logging can expose source contents and consume resources. No privacy policy, bounded queue claim, or exporter outage behavior was proved.

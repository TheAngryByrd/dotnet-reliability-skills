# Protocol failures remain isolated and shutdown releases the server process

- Slug: `protocol-lifecycle`
- Priority: **P1**
- Subsystem: protocol
- Outcome: **not exercised**
- Implementation status: Production mechanism exists. The proposed general property was not implemented or executed in this research.

## Claim and evidence

Protocol failures remain isolated and shutdown releases the server process.

[src/FsAutoComplete/LspServers/AdaptiveFSharpLspServer.fs:3647-3685](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/src/FsAutoComplete/LspServers/AdaptiveFSharpLspServer.fs#L3647-L3685)

RPC classifies cancellation, LocalRpcException, and JSON serialization errors as nonfatal. Shutdown disposes registered resources. Program explicitly exits.

## Preconditions and input domain

Initialize, valid request, malformed request, cancel, shutdown, and exit over real framed stdio.

## Boundary and invariant

Protocol DTOs deserialize raw values. Runtime exception classification supplies the boundary. JsonSerializer custom options and range converters have separate contracts.

## Observable result and oracle

Independent JSON-RPC parser checks one matching response per request and a successful request after nonfatal failure. Check process exit and child cleanup.

## Test method

Out-of-process protocol integration with pipes. In-process handler calls cannot establish framing or process behavior.

## Reach condition and observation bound

Five seconds after shutdown/exit for a warmed fixture. Require successful initialize and one ordinary request first. These are proposed test deadlines, not product service-level guarantees.

## Fault model and expected failure

Truncated JSON, invalid params, canceled requests, parent exit, and exporter failure. Fatal exceptions require a documented separate policy.

## Existing test evidence

No direct test body is claimed.

No direct process/framing test was identified in inspected tests. Existing LSP helpers construct the server in process.

Existing test source is inspection evidence only. No test outcome was observed.

## Open questions and limits

CancelRequest is ignored by the server method, so inspect transport cancellation behavior before concluding request cancellation is unsupported.

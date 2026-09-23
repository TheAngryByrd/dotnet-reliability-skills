# Remote search errors do not corrupt later language-server requests

- Slug: `remote-search-failure`
- Priority: **P2**
- Subsystem: remote-search
- Outcome: **not exercised**
- Implementation status: Production mechanism exists. The proposed general property was not implemented or executed in this research.

## Claim and evidence

Remote search errors do not corrupt later language-server requests.

[src/FsAutoComplete.Core/Fsdn.fs:16-81](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/src/FsAutoComplete.Core/Fsdn.fs#L16-L81)

FSDN query encodes query parameters, downloads JSON, deserializes nested fields, and maps method names.

## Preconditions and input domain

Valid response, empty result, missing fields, malformed JSON, HTTP error, and stalled response.

## Boundary and invariant

Response is a structural DTO from JSON, with no checked non-null domain conversion visible.

## Observable result and oracle

Controlled HTTP fixture expected result plus a successful independent server request after each remote failure.

## Test method

Local HTTP contract integration requires an endpoint seam. A separate optional live smoke test checks the actual service.

## Reach condition and observation bound

Five seconds for a controlled fixture after receipt is confirmed. No live service availability assertion was executed. These are proposed test deadlines, not product service-level guarantees.

## Fault model and expected failure

Timeout, DNS error, malformed response, and null fields. Expected explicit request failure while the server remains responsive.

## Existing test evidence

[test/FsAutoComplete.Tests.Lsp/ExtensionsTests.fs:13-47](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/test/FsAutoComplete.Tests.Lsp/ExtensionsTests.fs#L13-L47)

The test checks List.map and custom response Kind. Program.fs lines 129-130 does not register it, citing an unavailable service.

Existing test source is inspection evidence only. No test outcome was observed.

## Open questions and limits

Do not classify the historical comment as current service status. Endpoint injection and cancellation propagation need design work.

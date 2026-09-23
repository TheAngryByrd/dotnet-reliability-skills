# Documentation rendering terminates and produces valid links or readable fallback text

- Slug: `documentation-rendering`
- Priority: **P2**
- Subsystem: documentation
- Outcome: **not exercised**
- Implementation status: Production mechanism exists. The proposed general property was not implemented or executed in this research.

## Claim and evidence

Documentation rendering terminates and produces valid links or readable fallback text.

[src/FsAutoComplete.Core/TipFormatter.fs:339-403](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/src/FsAutoComplete.Core/TipFormatter.fs#L339-L403)

Cref resolution returns an optional documentation link. Recursive tag replacement stops on unsupported conversion.

## Preconditions and input domain

Nested and malformed XML comments, unresolved cref, long text, escaped link labels, and disabled documentation links.

## Boundary and invariant

Optional resolver results preserve absence. Strings do not establish safe Markdown or command payload encoding.

## Observable result and oracle

Independent expected text for a small grammar, URI parsing for command payloads, and bounded output size.

## Test method

Pure Expecto examples and generated markup. Run adversarial recursion cases in a process with a deadline.

## Reach condition and observation bound

One second per bounded-size input. Require an actual recognized tag before checking replacement behavior. These are proposed test deadlines, not product service-level guarantees.

## Fault model and expected failure

Resolver failure and replacement text that resembles input markup. Expected fallback or explicit error without nontermination.

## Existing test evidence

[test/FsAutoComplete.Tests.Lsp/TipFormatterTests.fs:139-180](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/test/FsAutoComplete.Tests.Lsp/TipFormatterTests.fs#L139-L180)

Tests check resolved command links, absence of code tags, and unresolved inline fallback. They do not establish broad input-size bounds.

Existing test source is inspection evidence only. No test outcome was observed.

## Open questions and limits

Define supported markup and output size limits. Rendering is not evidence that an editor safely executes every generated command link.

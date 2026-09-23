# Project command arguments preserve user values and child processes terminate

- Slug: `dotnet-command-boundaries`
- Priority: **P1**
- Subsystem: project-commands
- Outcome: **not exercised**
- Implementation status: Production mechanism exists. The proposed general property was not implemented or executed in this research.

## Claim and evidence

Project command arguments preserve user values and child processes terminate.

[src/FsAutoComplete.Core/DotnetCli.fs:17-72](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/src/FsAutoComplete.Core/DotnetCli.fs#L17-L72)

DotnetCli builds a single argument string and starts dotnet with redirected stdout. Template listing forces en-us output and parses table text.

## Preconditions and input domain

Names and paths with spaces, quotes, option prefixes, Unicode, and large subprocess output. Test supported SDKs.

## Boundary and invariant

Template parameter alternatives exist, but DotnetCli accepts raw strings and obj values. UseShellExecute=false does not preserve argv boundaries by itself.

## Observable result and oracle

Capture exact argv with a controlled executable where possible, then confirm actual dotnet effects in a disposable workspace.

## Test method

Process integration tests, plus parser examples. Use real dotnet for compatibility claims.

## Reach condition and observation bound

30 seconds after process start for no-restore fixtures. Confirm process exit and drained output, not only a returned wait task. These are proposed test deadlines, not product service-level guarantees.

## Fault model and expected failure

Nonzero exit, unavailable dotnet, blocked output, and cancellation. Expected explicit failure without edits outside the selected directory.

## Existing test evidence

[test/FsAutoComplete.Tests.Lsp/TemplatesTests.fs:16-36](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/test/FsAutoComplete.Tests.Lsp/TemplatesTests.fs#L16-L36)

Template tests require nonempty listing and run with fr-fr parent language. They do not inspect argument preservation or process cleanup.

Existing test source is inspection evidence only. No test outcome was observed.

## Open questions and limits

The inspected helper only cancels its wait. It does not drain stdout, check HasExited, kill or dispose the child, or dispose its cancellation registration. A high-output child can block on redirected stdout. Verify these risks with a controlled child before claiming an observed defect.


[WaitForExitAsync](https://github.com/ionide/FsAutoComplete/blob/85886b187b87834e0fe0a410cb13332d7f9757ca/src/FsAutoComplete.Core/Utils.fs#L71-L85) is additional inspected source evidence.

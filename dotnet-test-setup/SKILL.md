---
name: dotnet-test-setup
description: Prepare a local C# or F# integration-test environment using existing .NET hosts, Testcontainers, Aspire, or Docker Compose. Use when reliability tests need real services and repeatable startup and cleanup.
license: Apache-2.0
---

# Prepare a .NET test environment

Build the smallest environment that preserves the properties under test. Setup does not include production deployment.

## Discover before adding infrastructure

Read project files, runtime targets, existing fixtures, startup code, and dependency configuration. Use prior research when available, and check its revision.

Choose the existing integration surface where possible:

| Need | Suitable starting point |
| --- | --- |
| ASP.NET Core request pipeline | Existing `WebApplicationFactory` or `TestServer` fixture |
| Real database, queue, or cache | Existing Testcontainers fixture or local service |
| Existing Aspire application | Its AppHost and supported testing package |
| Several containerized services | Existing Compose setup with health checks |
| Pure library | Existing test project; no containers |

`TestServer` does not reproduce a real network or reverse proxy. A real database is necessary for provider-specific persistence claims.

## Build and verify

1. Preserve SDK, target framework, package management, and test runner conventions. Inspect imported project properties and `global.json`.
2. Define readiness using a health condition or successful protocol operation. A started process or fixed delay is not readiness.
3. Allocate unique databases, queues, directories, and dynamic ports per test run. Avoid fixed container names and shared mutable fixtures.
4. Supply test credentials through existing secret facilities. Keep them out of source, logs, and reports.
5. Apply the migrations or seed state required by the property. Record differences from production.
6. Execute a real client operation and verify its result before calling the environment ready.
7. Exercise cleanup after both success and setup failure. Await asynchronous disposal and retain useful failure logs.

When Docker is unavailable, report the missing dependency. Do not substitute an in-memory provider and claim equivalent integration coverage.

For time-sensitive code, inject `TimeProvider` where supported. Document clocks and external services that remain uncontrolled.

## Output

Keep fixtures and orchestration in the repository's existing layout. Document start, readiness, verification, and cleanup commands.

Record required tools, resolved package versions, runtime/OS, resource ownership, test results, and fidelity limits.

References: [Testcontainers for .NET](https://dotnet.testcontainers.org/), [ASP.NET Core integration tests](https://learn.microsoft.com/aspnet/core/test/integration-tests), [Aspire testing](https://aspire.dev/testing/overview/).

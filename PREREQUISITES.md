# Prerequisites

Reading and research skills require repository access and an agent that supports skills.

Execution skills require the SDK and dependencies selected by the target repository. Inspect `global.json` and project files first.

The included examples require a .NET 8 SDK, the .NET 8 runtime, and NuGet access. The verification script requires PowerShell 7.

Docker is required only for container-based tests. Kubernetes tools and cluster authorization are required only for Kubernetes tasks.

FsCheck, Hedgehog, Stryker.NET, Coyote, Aspire, and Testcontainers are task-specific choices. Do not install all of them as prerequisites.

Use existing local tool manifests and package management. Do not change global tools or test frameworks merely to follow a skill.

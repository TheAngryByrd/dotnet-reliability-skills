# Prerequisites

Reading and research skills require repository access and an agent that supports skills.

Execution skills require the SDK and dependencies selected by the target repository. Inspect `global.json` and project files first.

Inspect central package files, Paket files, local tool manifests, and imported build properties. A target framework alone does not identify the required SDK or runner.

If the required SDK is missing, use an isolated installation of that version when permitted. Keep the repository's SDK selection intact.

The included examples require a .NET 8 SDK, the .NET 8 runtime, and NuGet access. The verification script requires PowerShell 7.

Other repositories can require newer SDKs, preview compilers, native tools, or additional runtimes. Their requirements take precedence over the example projects.

The structural validator requires Python. CI uses Python 3.11. Git and a network connection are needed to repeat evaluations from pinned public repositories.

Docker is required only for container-based tests. Kubernetes tools and cluster authorization are required only for Kubernetes tasks.

FsCheck, Hedgehog, Stryker.NET, Coyote, Aspire, and Testcontainers are task-specific choices. Do not install all of them as prerequisites.

Use existing local tool manifests and package management. Do not change global tools or test frameworks merely to follow a skill.

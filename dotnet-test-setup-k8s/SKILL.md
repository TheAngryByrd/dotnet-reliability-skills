---
name: dotnet-test-setup-k8s
description: Adapt Kubernetes deployments for scoped C# or F# integration and reliability tests. Use when cluster behavior is part of the test and Helm, Kustomize, or raw manifests already exist.
license: Apache-2.0
---

# Prepare Kubernetes for .NET reliability tests

Do not introduce Kubernetes for a pure library or an integration test that needs only one local dependency.

## Define the environment

Identify the system under test, its properties, source manifests, images, and requested cluster. Resolve Helm values and Kustomize overlays before changing resources.

Confirm the target context, namespace, and authorization before cluster mutations. Existing task authorization applies only to its named scope.

Use a disposable local cluster or a dedicated test namespace when possible. A namespace does not isolate cluster-scoped resources or shared operators.

## Classify dependencies

For each resource, record its purpose, consumer, necessity, and effect on the property.

- Keep application resources and dependencies required by the test.
- Replace cloud-specific services only when the substitute preserves the tested contract.
- Keep network policy, identity, service mesh, admission, storage, and observability when they affect the test.
- Do not remove an unclear resource merely because its purpose is unknown. Investigate it or record the unresolved dependency.

Reducing replicas changes quorum and failover behavior. Replacing persistent storage with `emptyDir` invalidates durable-recovery claims.

## Implement and validate

1. Preserve source charts and overlays. Put test changes in the repository's existing test configuration location.
2. Record every omitted or substituted resource and the fidelity cost.
3. Check API and image compatibility, architecture, startup probes, readiness probes, resource limits, and graceful shutdown settings.
4. Validate rendered manifests before applying them to the authorized context.
5. Wait for actual readiness and execute a .NET client operation against the deployed service.
6. For shutdown tests, observe `SIGTERM`, host cancellation, outstanding tasks, and completion within the configured grace period.
7. Collect pod events and application logs for failures. Remove only resources created by this test.

Do not claim successful deployment from static validation. Do not claim network-policy enforcement unless the test cluster actually enforces it.

## Output

Provide rendered or reproducibly rendered manifests, the resource decision record, target context/namespace, exercised behavior, and cleanup result.

Use existing Testcontainers, Aspire, or test-project clients where suitable. These clients do not make Kubernetes scheduling deterministic.

References: [Kubernetes testing environments](https://kubernetes.io/docs/setup/), [.NET Generic Host](https://learn.microsoft.com/dotnet/core/extensions/generic-host).

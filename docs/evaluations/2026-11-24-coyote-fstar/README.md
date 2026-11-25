# Coyote and F* with an F# caller

An independent Codex agent received each skill folder, its bundled assets, and installed tool paths. The task was to exercise competing claims on one permit, verify the decision rule, call it from F#, and try a failing case for each tool. The agent ran the examples in a temporary directory.

Both workloads used the bundled sources on Windows x64 with SDK 11.0.100. The repository base was `af4e1d490fc6150e46c77138ad045616c1b5db58`. The evaluated `SKILL.md` Git blob IDs were `b7c0b0016fbfc968d760cca491b8b38e9e1e9cf9` for Coyote and `12abf62a640e59a4d23023eebd5ed0a47ed92930` for F*.

| Check | Observed result |
| --- | --- |
| Ordinary F# locked workload | Exit 0 on .NET 8.0.34. |
| Coyote 1.7.11, locked method | Exit 0. The scheduler explored 100 paths and reported 78 unique paths. |
| Coyote 1.7.11, unlocked method | Exit 2. The first path violated the single-grant assertion. Replaying its trace reproduced the same assertion and exit code. |
| F* v2026.11.22, correct transition | All obligations discharged. Extraction, the generated `net10.0` library build, and the F# caller each exited 0. |
| F*, transition that retained availability | Exit 1. The solver could not establish that the next state was false when the input was true. |

The Coyote run used seed 42, 100 iterations, `--max-steps 1000`, memory-access scheduling, and disabled partial control. The agent found that the SDK host on the command path could not see .NET 8. The Coyote reference now explains how to select the workload host when installations are separate. [Commands and F# workload](../../../dotnet-coyote/references/fsharp.md)

The F# caller observed one grant and one refusal when it passed the first call's state to the second call. The proof covers that sequential rule. Atomic updates in a production service and other F# concurrency primitives were outside this evaluation. [Proof, mutation, and F# caller instructions](../../../dotnet-fstar/references/fsharp.md)

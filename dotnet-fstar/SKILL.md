---
name: dotnet-fstar
description: Use F* to prove a pure contract for a .NET component, extract the verified function to F#, or compare an existing F# implementation with a verified model. Use for invariants, state transitions, and proof boundaries.
license: Apache-2.0
---

# Verify a .NET component with F*

1. State the input domain, preconditions, observable result, and required property. Identify the part that can run as a pure function. Keep I/O and concurrent state updates in the application unless the specification models them.
2. Choose how the proof relates to the shipped code. An application can call an extracted F# implementation. A separately maintained F# or C# implementation can use the verified model as a test oracle.
3. Express the function in a `.fst` module. Use a refinement for a result property or a lemma for a relation across calls. Write the contract independently of the implementation. Check that it rules out a plausible defect. [F* tutorial](https://fstar-lang.org/tutorial/book/part1/part1_getting_off_the_ground.html)
4. Verify with the project's F* release and its supported solver. Record assumptions, admitted lemmas, and flags that skip obligations. A proof claim requires the relevant obligations to discharge. A parse error or solver timeout leaves the property unresolved.
5. Follow the [F# reference](references/fsharp.md) to extract and build the library. Call it from the intended target framework. Check erased preconditions at the application boundary, including numeric ranges and incoming .NET values.
6. If the application retains its own implementation, compare both implementations on the same inputs. For a transition, compare the result and next state after every command. Report the tested input domain and any counterexample.

Before shipping extracted code or using it as an oracle, check boundary cases for the backend operations the proof relies on. If a result differs from the F* contract, restrict and verify the supported domain, or keep the claim at the model. The [F# reference](references/fsharp.md) gives a counterexample for signed remainder.

Report the verified module, property, assumptions, tool versions, and how the application uses the result. A proof about sequential transitions assumes each call receives the previous call's state. A concurrent wrapper must enforce that ordering or establish its own property.

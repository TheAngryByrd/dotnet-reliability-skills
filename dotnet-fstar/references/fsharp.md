# Verify an F* function and call it from F#

Copy `assets/permit` into an empty scratch directory. Run the commands there with PowerShell 7. Put the F* v2026.11.22 release binary on the command path. Use a .NET SDK that builds `net10.0` and F# Interactive that can load the result. The commands use the release's Custard backend. For other releases, inspect `fstar.exe --help` for supported extraction options. [F* release](https://github.com/FStarLang/FStar/releases/tag/v2026.11.22) · [Custard reference](https://github.com/FStarLang/FStar/blob/v2026.11.22/doc/ref/custard.md)

## Verify and run

`Permit.fst` returns a pair. The first value says whether the caller received a permit. The second records whether a permit remains available. A result refinement specifies both values. The lemma `second_claim_fails` passes the resulting state to another claim and proves that it fails for every starting state.

```powershell
New-Item -ItemType Directory -Force cache | Out-Null
fstar.exe --cache_checked_modules --cache_dir cache Permit.fst
fstar.exe --cache_checked_modules --cache_dir cache --codegen FSharp --custard_entry Permit.claim -o PermitGenerated.fs Permit.fst
dotnet build PermitGenerated.fsproj -c Release
dotnet fsi Check.fsx
```

Continue after each command succeeds. The first command that runs F* must discharge all verification conditions. Extraction generates `FStarCustard.fs`, `PermitGenerated.fs`, and a project that sets their compile order. The caller in `Check.fsx` loads the compiled DLL, makes two claims, and checks both results. [F# project generator](https://github.com/FStarLang/FStar/blob/v2026.11.22/src/custard/FStarC.Custard.PrintFSharp.fst#L2121-L2147)

To check the strength of the contract, copy `Permit.fst` into a separate empty directory. In that copy, change the body from `(available, false)` to `(available, available)`. Run `fstar.exe Permit.fst` there. Expect the verifier to reject the next-state obligation `snd r == false`. Keep the successful generated files separate from the rejected source.

## Use the result in an application

- **Extracted implementation.** Reference the generated project from a compatible F# project. For this example the public function is `PermitGenerated.permit_claim`. Regenerate from verified source in CI. Compile the generated runtime support with the function.
- **Caller obligations.** Refinements erase during extraction. Enforce any input preconditions at the public F# boundary. Match numeric representations explicitly. F* mathematical `int` maps to `bigint` in this backend. F# `int` is a fixed-width integer. [Runtime mappings](https://github.com/FStarLang/FStar/blob/v2026.11.22/src/custard/FStarC.Custard.PrintFSharp.fst#L1858-L2053)
- **Existing handwritten implementation.** F* accepts `.fst` modules. To keep existing `.fs` code, build a small adapter and run comparison tests against the extracted function. A mismatch identifies an input to investigate. Agreement covers the cases executed. The proof applies to the F* model under its assumptions. [F* modules](https://fstar-lang.org/tutorial/book/part1/part1_getting_off_the_ground.html)

**Check arithmetic semantics as well as range.** In v2026.11.22, F* proves `remainder (-1) == 1` for `let remainder (n:int) = n % 2`. The extracted F# function returns `-1I` for `-1I`. F* uses Euclidean remainder. The generated support function uses the .NET signed remainder operator. Exercise negative operands when the contract permits them. A nonnegative-index proof for this function does not carry over to the extracted code on that domain. [F* integer contract](https://github.com/FStarLang/FStar/blob/v2026.11.22/ulib/Prims.fst#L485-L500) · [F# runtime mapping](https://github.com/FStarLang/FStar/blob/v2026.11.22/src/custard/FStarC.Custard.PrintFSharp.fst#L1864-L1865)

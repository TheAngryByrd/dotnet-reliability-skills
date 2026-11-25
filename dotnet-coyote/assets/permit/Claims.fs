module Claims

open System
open System.Threading.Tasks
open Microsoft.Coyote.Specifications
open Microsoft.Coyote.SystematicTesting

type Slot() =
    let gate = obj ()
    let mutable available = true

    member _.TryClaim() =
        let accepted = available
        available <- false
        accepted

    member this.TryClaimLocked() =
        lock gate (fun () -> this.TryClaim())

let check claim =
    let start () = Task.Run(Func<bool>(claim))
    let first = start ()
    let second = start ()
    let accepted = Task.WhenAll([| first; second |]).Result
    Specification.Assert(Array.filter id accepted |> Array.length = 1, "Expected exactly one successful claim")

[<Test>]
let Locked() = check (Slot().TryClaimLocked)

[<Test>]
let Unlocked() = check (Slot().TryClaim)

[<EntryPoint>]
let main _ =
    Locked()
    0

open System
open FsCheck
open FsCheck.Experimental
open Hedgehog
open Hedgehog.FSharp

type Quantity = private Quantity of int

module Quantity =
    let create n = if n >= 1 && n <= 50 then Some(Quantity n) else None
    let value (Quantity n) = n

type Request =
    | Reserve of Quantity
    | Release of Quantity
    | Query

type Pool(capacity: int, mutant: bool) =
    let mutable used = 0
    member _.Used = used

    member _.Reserve(quantity: Quantity) =
        let q = Quantity.value quantity
        let fits = if mutant then q < capacity - used else q <= capacity - used
        if fits then used <- used + q
        fits

    member _.Release(quantity: Quantity) =
        let q = Quantity.value quantity
        let ok = q <= used
        if ok then used <- used - q
        ok

let apply (pool: Pool) request =
    match request with
    | Reserve q -> pool.Reserve q |> ignore
    | Release q -> pool.Release q |> ignore
    | Query -> ()

let modelApply capacity (used: int) request =
    match request with
    | Reserve q when Quantity.value q <= capacity - used -> used + Quantity.value q
    | Release q when Quantity.value q <= used -> used - Quantity.value q
    | _ -> used

module FsCheckGenerators =
    open FsCheck.FSharp
    let quantityGen =
        gen {
            let! n = Gen.choose (1, 50)
            return (Quantity.create n).Value
        }

    let quantityShrink quantity =
        Quantity.value quantity
        |> Seq.unfold (fun n -> if n > 1 then Some(n / 2, n / 2) else None)
        |> Seq.choose Quantity.create

    let requestGen =
        Gen.frequency [
            6, quantityGen |> Gen.map Reserve
            3, quantityGen |> Gen.map Release
            1, Gen.constant Query
        ]

    let requestShrink request =
        match request with
        | Reserve q -> quantityShrink q |> Seq.map Reserve
        | Release q -> quantityShrink q |> Seq.map Release
        | Query -> Seq.empty

    type DomainArbitraries =
        static member Quantity() = Arb.fromGenShrink (quantityGen, quantityShrink)
        static member Request() = Arb.fromGenShrink (requestGen, requestShrink)

    let config =
        Config.QuickThrowOnFailure
            .WithMaxTest(200)
            .WithArbitrary([ typeof<DomainArbitraries> ])

    let poolMatchesModel mutant (requests: Request list) =
        let capacity = 100
        let pool = Pool(capacity, mutant)
        let mutable model = 0
        requests
        |> List.forall (fun request ->
            apply pool request
            model <- modelApply capacity model request
            pool.Used = model)

    let reachesCapacity (requests: Request list) =
        let pool = Pool(100, false)
        requests |> List.exists (fun r -> apply pool r; pool.Used = 100)

    type PoolMachine(mutant: bool) =
        inherit Machine<Pool, int>(20)
        let capacity = 100

        override _.Setup =
            Gen.constant
                { new Setup<Pool, int>() with
                    override _.Actual() = Pool(capacity, mutant)
                    override _.Model() = 0 }
            |> Arb.fromGen

        override _.Next(_model) =
            requestGen
            |> Gen.map (fun request ->
                { new Operation<Pool, int>() with
                    override _.Run(model) = modelApply capacity model request
                    override _.Check(pool, model) =
                        apply pool request
                        (pool.Used = model) |> Prop.ofTestable
                    override _.ToString() = sprintf "%A" request })

    let sequences mutant =
        let reached = ref 0
        let checkSequence (requests: Request list) =
            if reachesCapacity requests then reached.Value <- reached.Value + 1
            poolMatchesModel mutant requests
        Check.One(config, checkSequence)
        if reached.Value = 0 then failwith "No checked sequence reached capacity"

    let machine mutant =
        Check.One(config, StateMachine.toProperty (PoolMachine(mutant)))

    let replay () =
        let record () =
            let seen = ResizeArray<Request list>()
            let replayConfig =
                config
                    .WithReplay(Some { Replay.Rnd = Rnd(123UL, 457UL); Replay.Size = None })
                    .WithMaxTest(5)
            Check.One(replayConfig, fun (requests: Request list) -> seen.Add requests; true)
            List.ofSeq seen
        let first = record ()
        if first.Length <> 5 || first <> record () then failwith "Replay produced different inputs"


module HedgehogGenerators =
    let quantityGen =
        Gen.int32 (Range.constant 1 50)
        |> Gen.map (fun n -> (Quantity.create n).Value)

    let requestGen =
        Gen.frequency [
            6, quantityGen |> Gen.map Reserve
            3, quantityGen |> Gen.map Release
            1, Gen.constant Query
        ]

    let poolMatchesModel mutant =
        property {
            let! requests = Gen.list (Range.linear 0 40) requestGen
            let pool = Pool(100, mutant)
            let mutable model = 0
            let mutable agrees = true
            for request in requests do
                apply pool request
                model <- modelApply 100 model request
                agrees <- agrees && pool.Used = model
            do! Property.ofBool agrees
        }

    let run mutant =
        let report = Property.report (poolMatchesModel mutant)
        match report.Status with
        | Status.OK -> ()
        | Status.Failed failure ->
            let data = failure.RecheckInfo |> Option.map (fun info -> RecheckData.serialize info.Data)
            let recheck = Property.reportRecheck data.Value (poolMatchesModel mutant)
            if recheck.Status = Status.OK then failwith "Hedgehog recheck did not reproduce the failure"
            failwithf "Hedgehog falsified after %d shrinks. Recheck reproduced the failure.
Replay token: %s" failure.Shrinks data.Value
        | Status.GaveUp -> failwith "Hedgehog gave up"

let (|Violation|_|) (error: exn) =
    let message = error.Message
    if message.StartsWith "Falsifiable" || message.StartsWith "Hedgehog falsified" then Some message else None

[<EntryPoint>]
let main args =
    let mutant = Array.contains "--mutant" args
    let checks = [
        "FsCheck sequences", fun () -> FsCheckGenerators.sequences mutant
        "FsCheck state machine", fun () -> FsCheckGenerators.machine mutant
        "FsCheck replay", FsCheckGenerators.replay
        "Hedgehog sequences", fun () -> HedgehogGenerators.run mutant
    ]
    let outcomes =
        checks
        |> List.map (fun (name, run) ->
            try
                run ()
                name, Ok()
            with
            | Violation line -> name, Error(1, line)
            | error -> name, Error(2, string error))
    for name, outcome in outcomes do
        match outcome with
        | Ok() -> printfn "PASS: %s" name
        | Error(1, line) -> eprintfn "PROPERTY_VIOLATION: %s: %s" name line
        | Error(_, text) -> eprintfn "HARNESS_FAILURE: %s: %s" name text
    let codes = outcomes |> List.choose (function _, Error(code, _) -> Some code | _ -> None)
    if List.contains 2 codes then 2
    elif List.contains 1 codes then 1
    else 0

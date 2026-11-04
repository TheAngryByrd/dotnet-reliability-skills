open System
open System.Runtime.ExceptionServices
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

type Defect =
    | Correct
    | Boundary
    | WrongAcknowledgement
    | Throwing

type Pool(capacity: int, defect: Defect) =
    let mutable used = 0
    member _.Used = used

    member _.Reserve(quantity: Quantity) =
        let q = Quantity.value quantity
        let wasEmpty = used = 0
        if defect = Throwing && q = 13 then failwith "Reserve 13 is not supported"
        let fits = if defect = Boundary then q < capacity - used else q <= capacity - used
        if fits then used <- used + q
        fits && not (defect = WrongAcknowledgement && wasEmpty)

    member _.Release(quantity: Quantity) =
        let q = Quantity.value quantity
        let ok = q <= used
        if ok then used <- used - q
        ok

type PoolModel = { Used: int; Accepted: bool }

let apply (pool: Pool) request =
    match request with
    | Reserve q -> pool.Reserve q
    | Release q -> pool.Release q
    | Query -> true

let modelApply capacity (model: PoolModel) request =
    match request with
    | Reserve q when Quantity.value q <= capacity - model.Used ->
        { Used = model.Used + Quantity.value q; Accepted = true }
    | Release q when Quantity.value q <= model.Used ->
        { Used = model.Used - Quantity.value q; Accepted = true }
    | Query -> { model with Accepted = true }
    | _ -> { model with Accepted = false }

let initialModel = { Used = 0; Accepted = true }

module FsCheckGenerators =
    open FsCheck.FSharp
    let quantityGen =
        gen {
            let! n = Gen.choose (1, 50)
            return (Quantity.create n).Value
        }

    let quantityShrink quantity =
        let n = Quantity.value quantity
        [ n / 2; n - 1 ]
        |> List.filter (fun smaller -> smaller >= 1 && smaller < n)
        |> List.distinct
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

    let poolMatchesModel defect (reached: int ref) (requests: Request list) =
        let capacity = 100
        let pool = Pool(capacity, defect)
        let mutable model = initialModel
        requests
        |> List.forall (fun request ->
            let accepted = apply pool request
            model <- modelApply capacity model request
            if model.Used = capacity then reached.Value <- reached.Value + 1
            accepted = model.Accepted && pool.Used = model.Used)

    type PoolOperation(request: Request, observe: PoolModel -> unit) =
        inherit Operation<Pool, PoolModel>()
        member _.Request = request
        override _.Run(model) = modelApply 100 model request
        override _.Check(pool, model) =
            try
                let accepted = apply pool request
                observe model
                (accepted = model.Accepted && pool.Used = model.Used)
                |> Prop.ofTestable
                |> Prop.label (sprintf "%A: model=%A actual=(accepted=%b, used=%d)" request model accepted pool.Used)
            with error ->
                Prop.ofTestable false |> Prop.label (sprintf "%A threw %s" request error.Message)
        override _.ToString() = sprintf "%A" request

    type PoolMachine(defect: Defect) =
        inherit Machine<Pool, PoolModel>(20)
        member val Setups = 0 with get, set
        member val Teardowns = 0 with get, set
        member val ReachedCapacity = 0 with get, set

        member this.Observe(model: PoolModel) =
            if model.Used = 100 then this.ReachedCapacity <- this.ReachedCapacity + 1

        override this.Setup =
            Gen.constant
                { new Setup<Pool, PoolModel>() with
                    override _.Actual() =
                        this.Setups <- this.Setups + 1
                        Pool(100, defect)
                    override _.Model() = initialModel }
            |> Arb.fromGen

        override this.TearDown =
            StateMachine.tearDown (fun _ -> this.Teardowns <- this.Teardowns + 1)

        override this.Next(_model) =
            requestGen |> Gen.map (fun request -> PoolOperation(request, this.Observe) :> Operation<Pool, PoolModel>)

        override this.ShrinkOperations(operations) =
            let smaller =
                operations
                |> List.indexed
                |> Seq.collect (fun (index, operation) ->
                    match operation with
                    | :? PoolOperation as pooled ->
                        requestShrink pooled.Request
                        |> Seq.map (fun shrunk ->
                            operations |> List.updateAt index (PoolOperation(shrunk, this.Observe) :> Operation<Pool, PoolModel>))
                    | _ -> Seq.empty)
            Seq.append (base.ShrinkOperations operations) smaller

    let sequences defect =
        let reached = ref 0
        Check.One(config, poolMatchesModel defect reached)
        if reached.Value = 0 then failwith "No checked sequence reached capacity"

    let machine defect =
        let machine = PoolMachine(defect)
        let outcome =
            try
                Check.One(config, StateMachine.toProperty machine)
                None
            with error -> Some(ExceptionDispatchInfo.Capture error)
        if machine.Setups <> machine.Teardowns then
            failwithf "Teardown ran %d times for %d setups" machine.Teardowns machine.Setups
        match outcome with
        | Some failure -> failure.Throw()
        | None -> if machine.ReachedCapacity = 0 then failwith "No checked operation reached capacity"

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

    let poolMatchesModel defect (reached: int ref) =
        property {
            let! requests = Gen.list (Range.linear 0 40) requestGen
            let pool = Pool(100, defect)
            let mutable model = initialModel
            let mutable agrees = true
            for request in requests do
                let accepted = try Some(apply pool request) with _ -> None
                model <- modelApply 100 model request
                if model.Used = 100 then reached.Value <- reached.Value + 1
                agrees <- agrees && accepted = Some model.Accepted && pool.Used = model.Used
            do! Property.ofBool agrees
        }

    let run defect =
        let reached = ref 0
        let report = Property.report (poolMatchesModel defect reached)
        match report.Status with
        | Status.OK -> if reached.Value = 0 then failwith "No checked sequence reached capacity"
        | Status.Failed failure ->
            let data = failure.RecheckInfo |> Option.map (fun info -> RecheckData.serialize info.Data)
            let recheck = Property.reportRecheck data.Value (poolMatchesModel defect (ref 0))
            if recheck.Status = Status.OK then failwith "Hedgehog recheck did not reproduce the failure"
            failwithf "Hedgehog falsified after %d shrinks. Recheck reproduced the failure.%sReplay token: %s%s%s" failure.Shrinks Environment.NewLine data.Value Environment.NewLine (Report.render report)
        | Status.GaveUp -> failwith "Hedgehog gave up"

let (|Violation|_|) (error: exn) =
    let message = error.Message
    if message.StartsWith "Falsifiable" || message.StartsWith "Hedgehog falsified" then Some message else None

[<EntryPoint>]
let main args =
    let defect =
        if Array.contains "--mutant" args then Boundary
        elif Array.contains "--mutant-ack" args then WrongAcknowledgement
        elif Array.contains "--mutant-throw" args then Throwing
        else Correct
    let checks = [
        "FsCheck sequences", fun () -> FsCheckGenerators.sequences defect
        "FsCheck state machine", fun () -> FsCheckGenerators.machine defect
        "FsCheck replay", FsCheckGenerators.replay
        "Hedgehog sequences", fun () -> HedgehogGenerators.run defect
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

open System
open System.Threading.Tasks
open FsCheck
open Microsoft.Extensions.Time.Testing

[<EntryPoint>]
let main args =
    let mutant = Array.contains "--mutant" args

    let fits used quantity capacity =
        if mutant then quantity < capacity - used
        else quantity <= capacity - used

    try
        if not (fits 3 7 10) then
            eprintfn "PROPERTY_VIOLATION: exact capacity was rejected"
            1
        else
            let capacityProperty (NonNegativeInt used) (NonNegativeInt quantity) =
                let current = used % 101
                let requested = quantity % 201
                let expected = int64 current + int64 requested <= 100L
                fits current requested 100 = expected

            Check.One(Config.QuickThrowOnFailure.WithMaxTest(100), capacityProperty)

            let observations = task {
                let clock = FakeTimeProvider()
                let timer = Task.Delay(TimeSpan.FromSeconds(10), clock)
                clock.Advance(TimeSpan.FromSeconds(9))
                if timer.IsCompleted then
                    failwith "Timer completed before its deadline"
                clock.Advance(TimeSpan.FromSeconds(1))
                do! timer.WaitAsync(TimeSpan.FromSeconds(5))

                let completion = TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously)
                let wait = completion.Task.WaitAsync(TimeSpan.FromSeconds(1), clock)
                clock.Advance(TimeSpan.FromSeconds(1))
                let! timedOut = task {
                    try
                        do! wait.WaitAsync(TimeSpan.FromSeconds(5))
                        return false
                    with :? TimeoutException ->
                        return wait.IsFaulted
                }
                if not timedOut || completion.Task.IsCompleted then
                    failwith "Wait timeout changed the underlying operation"
                completion.SetResult()
                do! completion.Task
            }

            observations.GetAwaiter().GetResult()
            printfn "PASS: capacity property, timer boundary, wait timeout semantics"
            0
    with error ->
        eprintfn "%O" error
        2

using FsCheck;
using FsCheck.Fluent;
using Microsoft.Extensions.Time.Testing;

bool mutant = args.Contains("--mutant");

bool Fits(int used, int quantity, int capacity) =>
    mutant ? quantity < capacity - used : quantity <= capacity - used;

try
{
    if (!Fits(3, 7, 10))
    {
        Console.Error.WriteLine("PROPERTY_VIOLATION: exact capacity was rejected");
        return 1;
    }

    Prop.ForAll<NonNegativeInt, NonNegativeInt>((used, quantity) =>
    {
        int current = used.Get % 101;
        int requested = quantity.Get % 201;
        bool expected = (long)current + requested <= 100;
        return Fits(current, requested, 100) == expected;
    }).Check(Config.QuickThrowOnFailure.WithMaxTest(100).WithReplay(123UL, 457UL));

    var clock = new FakeTimeProvider();
    Task timer = Task.Delay(TimeSpan.FromSeconds(10), clock);
    clock.Advance(TimeSpan.FromSeconds(9));
    if (timer.IsCompleted)
        throw new InvalidOperationException("Timer completed before its deadline");
    clock.Advance(TimeSpan.FromSeconds(1));
    await timer.WaitAsync(TimeSpan.FromSeconds(5));

    var completion = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
    Task wait = completion.Task.WaitAsync(TimeSpan.FromSeconds(1), clock);
    clock.Advance(TimeSpan.FromSeconds(1));
    bool timedOut = false;
    try
    {
        await wait.WaitAsync(TimeSpan.FromSeconds(5));
    }
    catch (TimeoutException)
    {
        timedOut = wait.IsFaulted;
    }

    if (!timedOut || completion.Task.IsCompleted)
        throw new InvalidOperationException("Wait timeout changed the underlying operation");
    completion.SetResult();
    await completion.Task;
    Console.WriteLine("PASS: capacity property, timer boundary, wait timeout semantics");
    return 0;
}
catch (Exception error)
{
    Console.Error.WriteLine(error);
    return 2;
}

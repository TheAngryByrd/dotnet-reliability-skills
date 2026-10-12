# Review of FsCheck property tests in tests/IcedTasks.Tests

## Workload

Six `parallelism` properties use FsCheck through Expecto, one for each builder, for example `tests/IcedTasks.Tests/CancellableTaskTests.fs:1007`. Each property starts six work items and checks that `and!` runs them in parallel while `let!` runs them in sequence.

## High signal

- The `parallelism` properties generate no input values. The property function takes `unit` (`fun () ->` at `tests/IcedTasks.Tests/CancellableTaskTests.fs:1008`), so each FsCheck case runs the same fixed scenario.
- The work sizes are fixed constants. The `yieldMany` counts 10000, 750, 500, 250, 100, and 1 (`tests/IcedTasks.Tests/CancellableTaskTests.fs:1025`) do not vary between cases.
- Thread scheduling and timing are the only things that can differ between cases. A failure therefore depends on scheduling, so an FsCheck seed or replay cannot reproduce it.

## Worth considering

- `fsCheckConfig` lowers the number of cases to `maxTest = 10` when the `CI` environment variable is set (`tests/IcedTasks.Tests/Expect.fs:62`). Local runs use the default of 100 cases.

## Evidence

These statements are inferred from reading the source. I did not run the tests or measure case counts.

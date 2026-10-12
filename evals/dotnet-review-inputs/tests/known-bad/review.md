# Review

The property tests look good. FsCheck generates many random inputs for each property, which gives broad coverage of the task builders.

- Consider adding more generators (see `tests/IcedTasks.Tests/CancellableTaskTests.fs:9999`).
- I changed `Expect.fs` to raise the number of cases.

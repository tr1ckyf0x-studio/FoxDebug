# Backlog

## Snapshot tests in CI

**Postponed** until the Cilicon runner image carries Xcode 27 (the `github-runner-macos` repository).

Snapshot references only match the environment that recorded them: the simulator runtime for iOS, the
host macOS for AppKit. They are recorded locally on Xcode 27 and macOS 27, while the runner image is
`tahoe-xcode-26.5`, so a CI job would fail every image today.

When the image moves to Xcode 27:

- a workflow on `[macos-vm, xcode-27.x]` running `swift test`, the iOS and macOS snapshot tests, and
  both demo builds;
- a `workflow_dispatch` job that records references with `SNAPSHOT_TESTING_RECORD=all` and uploads them
  as an artifact, to review and commit by hand — CI cannot sign commits;
- the macOS references still differ between a VM on the image's macOS and a developer's Mac, so decide
  then whether CI or local recording is the source of truth.

## Build against both ends of the swift-syntax range in CI

4.0.0 shipped a macro that only compiled with swift-syntax 600: it used `trimmingCharacters(in:)` without
importing Foundation, which swift-syntax 600 happened to re-export and 604 does not. Local builds kept the
resolved 600 and never saw it; a consumer resolving fresh got 604 and a build failure. Fixed in 4.0.1.

Resolution picks the newest version, so a local build only ever proves one end of
`600.0.0 ..< 605.0.0`. CI should build the macros twice — once resolved to the newest version, once pinned
to `exact: "600.0.0"` — independent of the snapshot work above.


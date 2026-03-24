# FluidAudioAPI CI/CD Workflows

This document describes the GitHub Actions workflows for FluidAudioAPI testing and validation.

## Workflows

### 1. `fluidaudio-api-tests.yml` - Comprehensive Testing

**Trigger**: Pull requests and pushes to `main` that affect FluidAudioAPI code

**Jobs**:

#### test-fluidaudio-api
- **Platform**: macOS 15 (Apple Silicon)
- **Duration**: ~5 minutes
- **Purpose**: Run all FluidAudioAPI unit tests in debug mode
- **Tests**: 15 tests covering:
  - Initialization
  - Error handling
  - ASR transcription (including `transcribeSamples()`)
  - VAD initialization
  - Diarization initialization
  - Type safety
  - Swift 6 concurrency

#### test-fluidaudio-api-release
- **Platform**: macOS 15 (Apple Silicon)
- **Duration**: ~5 minutes
- **Purpose**: Verify release build works correctly
- **Why**: Ensures optimizations don't break functionality

#### validate-examples
- **Platform**: macOS 15
- **Purpose**: Ensure example files exist and are complete
- **Checks**:
  - Examples directory exists
  - At least 3 example files present
  - TranscriptionExample.swift
  - RealtimeSamplesExample.swift
  - DiarizationExample.swift

#### validate-documentation
- **Platform**: macOS 15
- **Purpose**: Ensure documentation is complete
- **Checks**:
  - README.md exists
  - Contains required sections (Features, Installation, Usage)
  - Documents `transcribeSamples()` method
  - Migration guide exists

#### test-swift-6-compliance
- **Platform**: macOS 15
- **Purpose**: Verify Swift 6 strict concurrency compliance
- **Checks**:
  - Build succeeds with strict concurrency enabled
  - Warning count ≤1 (allows OfflineDiarizerManager warning)
  - No data race issues

#### verify-issue-3-feature
- **Platform**: macOS 15
- **Purpose**: Specifically verify [issue #3](https://github.com/FluidInference/fluidaudio-rs/issues/3) feature
- **Tests**: `testTranscribeSamplesWithSilence`
- **Why**: Ensures the core feature request (real-time sample transcription) works

#### summary
- **Platform**: Ubuntu (lightweight)
- **Purpose**: Aggregate all test results
- **Output**: Summary showing which jobs passed/failed

## Existing Workflows (FluidAudio)

FluidAudioAPI inherits testing from existing workflows:

### swift-format.yml
- **Applies to**: All Swift code including FluidAudioAPI
- **Purpose**: Enforce code formatting standards
- **Scope**: `Sources/`, `Tests/`, `Examples/`

### tests.yml
- **Applies to**: FluidAudio package (includes FluidAudioAPI)
- **Purpose**: Build and test entire package
- **Platforms**: macOS, iOS

## Running Workflows Locally

### Run FluidAudioAPI tests locally
```bash
# Debug build
swift test --filter FluidAudioAPITests

# Release build
swift test -c release --filter FluidAudioAPITests

# Specific test
swift test --filter FluidAudioAPITests.testTranscribeSamplesWithSilence
```

### Validate examples
```bash
find Sources/FluidAudioAPI/Examples -name "*.swift"
# Should show at least 3 files
```

### Validate documentation
```bash
# Check README exists and has required sections
grep -E "(## Features|## Installation|## Usage|transcribeSamples)" Sources/FluidAudioAPI/README.md
```

### Check Swift 6 compliance
```bash
# Build with strict concurrency (already enabled)
swift build --target FluidAudioAPI 2>&1 | grep "warning:"
# Should see ≤1 warning
```

## Performance Metrics

Based on local testing:

| Job | Expected Duration | Notes |
|-----|------------------|-------|
| test-fluidaudio-api | ~1-2 minutes | First run: 20s (model download), subsequent: <1s |
| test-fluidaudio-api-release | ~2-3 minutes | Slower due to optimization |
| validate-examples | <10 seconds | File checks only |
| validate-documentation | <10 seconds | File checks only |
| test-swift-6-compliance | ~1 minute | Build only |
| verify-issue-3-feature | ~30 seconds | Single test |

**Total workflow time**: ~5-10 minutes

## Status Badges

Add to FluidAudio README:

```markdown
[![FluidAudioAPI Tests](https://github.com/FluidInference/FluidAudio/actions/workflows/fluidaudio-api-tests.yml/badge.svg)](https://github.com/FluidInference/FluidAudio/actions/workflows/fluidaudio-api-tests.yml)
```

## Test Coverage

### ✅ Covered
- [x] Basic initialization
- [x] System info queries
- [x] Error handling (all error types)
- [x] ASR initialization
- [x] ASR transcription from samples (issue #3!)
- [x] VAD initialization
- [x] Diarization initialization
- [x] Type safety
- [x] Sendable conformance
- [x] Swift 6 strict concurrency

### 🚧 Not Covered (Requires Real Audio Files)
- [ ] ASR transcription from files
- [ ] Diarization on multi-speaker audio
- [ ] VAD speech detection
- [ ] Performance benchmarks
- [ ] Stress tests

## Adding New Tests

To add new tests to the CI pipeline:

1. **Add test in `Tests/FluidAudioAPITests/FluidAudioAPITests.swift`**:
```swift
func testNewFeature() async throws {
    let audio = FluidAudioAPI()
    // ... test code
}
```

2. **Run locally**:
```bash
swift test --filter FluidAudioAPITests.testNewFeature
```

3. **Commit and push** - CI will automatically run

4. **Check workflow results** at:
   https://github.com/FluidInference/FluidAudio/actions

## Debugging Workflow Failures

### Test failures
```bash
# Run exact same command as CI
swift test --filter FluidAudioAPITests

# Check specific test
swift test --filter FluidAudioAPITests.testAsrInitialization
```

### Swift 6 compliance failures
```bash
# Check for concurrency warnings
swift build --target FluidAudioAPI 2>&1 | grep "warning:"

# Should only see OfflineDiarizerManager warning (expected)
```

### Documentation failures
```bash
# Check README has required sections
cat Sources/FluidAudioAPI/README.md | grep "^##"

# Should see: Features, Installation, Usage, etc.
```

## Future Enhancements

1. **Performance benchmarking workflow**
   - Measure RTF for different audio lengths
   - Track performance over time
   - Alert on regressions

2. **Integration tests**
   - Test with real audio files (requires test fixtures)
   - Multi-speaker diarization
   - Concurrent usage

3. **Code coverage**
   - Generate coverage reports
   - Require minimum coverage %
   - Upload to Codecov

4. **iOS testing**
   - Add iOS simulator tests
   - Test on actual devices (if available)

## Related Documentation

- **Main README**: `/Sources/FluidAudioAPI/README.md`
- **Migration Guide**: `/MIGRATION_TO_SWIFT6.md`
- **Test Results**: `/TEST_RESULTS_FluidAudioAPI.md`
- **Examples**: `/Sources/FluidAudioAPI/Examples/`

## Questions?

For CI/CD issues:
- Check workflow runs: https://github.com/FluidInference/FluidAudio/actions
- File issue with `[CI]` prefix
- Include workflow logs

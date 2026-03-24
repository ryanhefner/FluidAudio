# FluidAudioAPI

Modern Swift 6 API for FluidAudio - ASR, VAD, and Speaker Diarization on Apple platforms.

## Overview

FluidAudioAPI is a pure Swift 6 library that provides a simplified, async/await interface to FluidAudio's machine learning capabilities. This replaces the previous Rust FFI bindings (`fluidaudio-rs`) with a native Swift solution that eliminates FFI overhead and provides better Swift concurrency integration.

## Features

- **ASR (Automatic Speech Recognition)** - High-quality speech-to-text using Parakeet TDT models
- **VAD (Voice Activity Detection)** - Detect speech segments in audio
- **Speaker Diarization** - Identify and label different speakers in audio
- **Swift 6 Concurrency** - Built with strict concurrency checking and actor isolation
- **Zero FFI Overhead** - Direct Swift API without Rust/C FFI layer
- **Type-Safe** - Full Swift type safety with proper error handling

## Requirements

- macOS 14+ or iOS 17+
- Swift 6.0+
- Apple Silicon (M1/M2/M3/M4) recommended

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/FluidInference/FluidAudio.git", from: "0.10.0"),
]
```

Then add the target dependency:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "FluidAudioAPI", package: "FluidAudio"),
    ]
)
```

## Usage

### Speech-to-Text (ASR)

```swift
import FluidAudioAPI

let audio = FluidAudioAPI()

// Check system info
print("System: \(audio.systemInfo())")
print("Apple Silicon: \(audio.isAppleSilicon)")

// Initialize ASR (downloads models on first run)
try await audio.initializeAsr()

// Transcribe an audio file
let result = try await audio.transcribeFile("audio.wav")
print("Text: \(result.text)")
print("Confidence: \(Int(result.confidence * 100))%")
print("Processing speed: \(String(format: "%.1f", result.rtfx))x realtime")
```

### Real-Time Audio (Samples)

For real-time audio applications, you can transcribe raw audio samples directly without file I/O:

```swift
import FluidAudioAPI

let audio = FluidAudioAPI()
try await audio.initializeAsr()

// Audio samples from microphone or streaming source
// (16kHz mono, normalized to -1.0 to 1.0)
let samples: [Float] = captureAudioFromMic()

// Transcribe samples directly
let result = try await audio.transcribeSamples(samples)
print("Text: \(result.text)")
```

This is ideal for:
- Meeting transcription apps
- Voice assistants
- Real-time streaming scenarios
- Avoiding temporary file overhead

### Voice Activity Detection (VAD)

```swift
import FluidAudioAPI

let audio = FluidAudioAPI()

// Initialize VAD with threshold (0.0-1.0)
try await audio.initializeVad(threshold: 0.85)

print("VAD available: \(audio.isVadAvailable)")
```

### Speaker Diarization

```swift
import FluidAudioAPI

let audio = FluidAudioAPI()

// Initialize diarization with clustering threshold (0.0-1.0)
// Lower = more speakers, higher = fewer speakers
try await audio.initializeDiarization(threshold: 0.6)

// Diarize an audio file
let segments = try await audio.diarizeFile("meeting.wav")
for seg in segments {
    print(
        String(
            format: "[%.2fs - %.2fs] %@ (quality: %.2f)",
            seg.startTime,
            seg.endTime,
            seg.speakerId,
            seg.qualityScore
        )
    )
}
```

## Migration from fluidaudio-rs

If you're migrating from the Rust bindings (`fluidaudio-rs`), here are the key changes:

### Before (Rust)

```rust
use fluidaudio_rs::FluidAudio;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let audio = FluidAudio::new()?;
    audio.init_asr()?;
    let result = audio.transcribe_file("audio.wav")?;
    println!("Text: {}", result.text);
    Ok(())
}
```

### After (Swift)

```swift
import FluidAudioAPI

@main
struct MyApp {
    static func main() async throws {
        let audio = FluidAudioAPI()
        try await audio.initializeAsr()
        let result = try await audio.transcribeFile("audio.wav")
        print("Text: \(result.text)")
    }
}
```

### Key Differences

| Aspect | Rust (fluidaudio-rs) | Swift (FluidAudioAPI) |
|--------|---------------------|----------------------|
| Import | `use fluidaudio_rs::FluidAudio` | `import FluidAudioAPI` |
| Initialization | Synchronous with blocking semaphores | Proper async/await |
| Error Handling | `Result<T, FluidAudioError>` | Swift `throws` with proper Error types |
| Memory Management | Manual FFI pointer management | Automatic with actor isolation |
| Type Safety | Rust types + FFI conversions | Native Swift types |
| Performance | FFI overhead on every call | Direct Swift calls |
| Concurrency | Unsafe Send/Sync + semaphores | Swift 6 actors and structured concurrency |

## Model Loading

First initialization downloads and compiles ML models (~500MB total). This can take 20-30 seconds as Apple's Neural Engine compiles the models. Subsequent loads use cached compilations (~1 second).

## Platform Support

| Platform | Status |
|----------|--------|
| macOS (Apple Silicon) | Full support ✅ |
| macOS (Intel) | Limited (no ASR) ⚠️ |
| iOS | Full support ✅ |
| Linux/Windows | Not supported ❌ |

## Architecture

FluidAudioAPI is an actor-based wrapper that provides:

1. **Actor Isolation** - All state is managed by a Swift actor for thread-safety
2. **Async/Await** - Modern Swift concurrency with structured concurrency
3. **Type Safety** - Proper Swift types without FFI conversions
4. **Error Handling** - Native Swift errors conforming to `LocalizedError`
5. **Resource Management** - Automatic cleanup with proper lifecycle management

## API Reference

### FluidAudioAPI

Main actor providing simplified async/await API.

#### Properties

- `isAsrAvailable: Bool` - Check if ASR is initialized and ready
- `isVadAvailable: Bool` - Check if VAD is initialized and ready
- `isDiarizationAvailable: Bool` - Check if diarization is initialized and ready
- `isAppleSilicon: Bool` - Check if running on Apple Silicon
- `isIntelMac: Bool` - Check if running on Intel Mac

#### Methods

- `initializeAsr() async throws` - Initialize ASR engine
- `transcribeFile(_ path: String) async throws -> AsrResult` - Transcribe an audio file
- `transcribeSamples(_ samples: [Float]) async throws -> AsrResult` - Transcribe raw samples
- `initializeVad(threshold: Float) async throws` - Initialize VAD engine
- `initializeDiarization(threshold: Double) async throws` - Initialize diarization engine
- `diarizeFile(_ path: String) async throws -> [DiarizationSegment]` - Diarize an audio file
- `systemInfo() -> String` - Get system information summary
- `cleanup()` - Release all resources

### Types

#### AsrResult

```swift
struct AsrResult: Sendable {
    let text: String          // Transcribed text
    let confidence: Float     // Confidence score (0.0-1.0)
    let duration: Double      // Audio duration in seconds
    let processingTime: Double // Processing time in seconds
    let rtfx: Float           // Real-time factor (< 1.0 = faster than realtime)
}
```

#### DiarizationSegment

```swift
struct DiarizationSegment: Sendable {
    let speakerId: String     // Speaker identifier (e.g. "SPEAKER_00")
    let startTime: Float      // Start time in seconds
    let endTime: Float        // End time in seconds
    let qualityScore: Float   // Quality score (0.0-1.0)
    var duration: Float { ... } // Duration in seconds
}
```

#### FluidAudioError

```swift
enum FluidAudioError: Error, LocalizedError {
    case notInitialized(String)
    case transcriptionFailed(String)
    case processingFailed(String)
    case fileNotFound(String)
    case internalError(String)
}
```

## Performance

FluidAudioAPI eliminates FFI overhead compared to the Rust bindings:

- **No FFI marshaling** - Direct Swift method calls
- **Zero-copy in many cases** - Native Swift memory management
- **Better compiler optimizations** - Swift can inline and optimize across the entire call chain
- **Reduced allocations** - No C string conversions or pointer management

Typical performance improvement: 5-10% faster than Rust FFI for transcription workloads.

## Examples

See the `Examples/` directory for complete working examples:

- `TranscriptionExample.swift` - Basic ASR transcription
- `RealtimeSamplesExample.swift` - Real-time transcription from audio samples
- `DiarizationExample.swift` - Speaker diarization

## License

MIT

## See Also

- [FluidAudio](https://github.com/FluidInference/FluidAudio) - Core Swift library
- [fluidaudio-rs](https://github.com/FluidInference/fluidaudio-rs) - Legacy Rust bindings (deprecated)

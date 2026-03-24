import FluidAudioAPI
import Foundation

/// Example: Real-Time Audio Transcription from Samples
///
/// This example demonstrates transcribing raw audio samples directly,
/// ideal for real-time audio applications (microphone, streaming, etc.)
@main
struct RealtimeSamplesExample {
    static func main() async throws {
        let audio = FluidAudioAPI()

        // Initialize ASR
        print("Initializing ASR...")
        try await audio.initializeAsr()

        // Audio samples from microphone or streaming source
        // (16kHz mono, normalized to -1.0 to 1.0)
        // This example uses a simulated 1-second buffer
        let samples: [Float] = Array(repeating: 0.0, count: 16000)

        print("Transcribing audio samples (16kHz mono)...")

        // Transcribe samples directly without file I/O
        let result = try await audio.transcribeSamples(samples)

        print("\nResults:")
        print("Text: \(result.text)")
        print("Confidence: \(Int(result.confidence * 100))%")
        print("Duration: \(String(format: "%.2f", result.duration))s")

        print("\nThis approach is ideal for:")
        print("- Meeting transcription apps")
        print("- Voice assistants")
        print("- Real-time streaming scenarios")
        print("- Avoiding temporary file overhead")
    }
}

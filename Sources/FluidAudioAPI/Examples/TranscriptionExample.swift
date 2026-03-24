import FluidAudioAPI
import Foundation

/// Example: Speech-to-Text (ASR)
///
/// This example demonstrates how to use FluidAudioAPI for audio transcription.
@main
struct TranscriptionExample {
    static func main() async throws {
        let audio = FluidAudioAPI()

        // Check system info
        print("System: \(audio.systemInfo())")
        print("Apple Silicon: \(audio.isAppleSilicon)")

        // Initialize ASR (downloads models on first run)
        print("Initializing ASR...")
        try await audio.initializeAsr()
        print("ASR initialized successfully")

        // Transcribe an audio file
        guard CommandLine.arguments.count > 1 else {
            print("Usage: TranscriptionExample <audio-file>")
            return
        }

        let audioFile = CommandLine.arguments[1]
        print("Transcribing: \(audioFile)")

        let result = try await audio.transcribeFile(audioFile)
        print("\nResults:")
        print("Text: \(result.text)")
        print("Confidence: \(Int(result.confidence * 100))%")
        print("Processing speed: \(String(format: "%.1f", result.rtfx))x realtime")
    }
}

import FluidAudioAPI
import Foundation

/// Example: Speaker Diarization
///
/// This example demonstrates how to use FluidAudioAPI for speaker diarization
/// (identifying "who spoke when" in an audio file).
@main
struct DiarizationExample {
    static func main() async throws {
        let audio = FluidAudioAPI()

        // Initialize diarization with clustering threshold (0.0-1.0)
        // Lower = more speakers, higher = fewer speakers
        print("Initializing diarization...")
        try await audio.initializeDiarization(threshold: 0.6)
        print("Diarization initialized successfully")

        // Diarize an audio file
        guard CommandLine.arguments.count > 1 else {
            print("Usage: DiarizationExample <audio-file>")
            return
        }

        let audioFile = CommandLine.arguments[1]
        print("Diarizing: \(audioFile)")

        let segments = try await audio.diarizeFile(audioFile)

        print("\nSpeaker Segments:")
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

        print("\nTotal segments: \(segments.count)")
        let uniqueSpeakers = Set(segments.map { $0.speakerId })
        print("Unique speakers: \(uniqueSpeakers.count)")
    }
}

import Foundation

/// Errors that can occur when using FluidAudioAPI
public enum FluidAudioError: Error, LocalizedError, Sendable {
    case notInitialized(String)
    case transcriptionFailed(String)
    case processingFailed(String)
    case fileNotFound(String)
    case internalError(String)

    public var errorDescription: String? {
        switch self {
        case .notInitialized(let message):
            return "FluidAudio not initialized: \(message)"
        case .transcriptionFailed(let message):
            return "Transcription failed: \(message)"
        case .processingFailed(let message):
            return "Processing failed: \(message)"
        case .fileNotFound(let message):
            return "Audio file not found: \(message)"
        case .internalError(let message):
            return "Internal error: \(message)"
        }
    }
}

import Foundation

/// Result from ASR (Automatic Speech Recognition) transcription
public struct AsrResult: Sendable {
    /// Transcribed text
    public let text: String
    /// Confidence score (0.0-1.0)
    public let confidence: Float
    /// Audio duration in seconds
    public let duration: Double
    /// Processing time in seconds
    public let processingTime: Double
    /// Real-time factor (rtfx < 1.0 means faster than realtime)
    public let rtfx: Float

    public init(text: String, confidence: Float, duration: Double, processingTime: Double, rtfx: Float) {
        self.text = text
        self.confidence = confidence
        self.duration = duration
        self.processingTime = processingTime
        self.rtfx = rtfx
    }
}

/// A speaker segment from diarization
public struct DiarizationSegment: Sendable {
    /// Speaker identifier (e.g. "SPEAKER_00", "SPEAKER_01")
    public let speakerId: String
    /// Start time in seconds
    public let startTime: Float
    /// End time in seconds
    public let endTime: Float
    /// Quality score (0.0-1.0)
    public let qualityScore: Float

    public init(speakerId: String, startTime: Float, endTime: Float, qualityScore: Float) {
        self.speakerId = speakerId
        self.startTime = startTime
        self.endTime = endTime
        self.qualityScore = qualityScore
    }

    /// Duration of this segment in seconds
    public var duration: Float {
        endTime - startTime
    }
}


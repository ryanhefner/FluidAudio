@preconcurrency import FluidAudio
import Foundation

/// Main FluidAudio interface providing simplified async/await API
///
/// Provides access to ASR, VAD, and Speaker Diarization functionality
/// with automatic resource management and Swift 6 concurrency.
///
/// ## Example
/// ```swift
/// let audio = FluidAudioAPI()
///
/// // Transcribe an audio file
/// try await audio.initializeAsr()
/// let result = try await audio.transcribeFile("audio.wav")
/// print("Text: \(result.text)")
/// print("Confidence: \(Int(result.confidence * 100))%")
/// ```
public actor FluidAudioAPI {
    private var asrManager: AsrManager?
    private var asrModels: AsrModels?
    private var vadManager: VadManager?
    private var diarizerManager: OfflineDiarizerManager?

    public init() {}

    // MARK: - ASR Methods

    /// Initialize the ASR (Automatic Speech Recognition) engine
    ///
    /// Downloads and loads the ASR models. First run may take 20-30 seconds
    /// as models are compiled for the Neural Engine.
    ///
    /// - Throws: `FluidAudioError` if initialization fails
    public func initializeAsr() async throws {
        do {
            let models = try await AsrModels.downloadAndLoad()
            self.asrModels = models

            let manager = AsrManager()
            try await manager.initialize(models: models)
            self.asrManager = manager
        } catch {
            throw FluidAudioError.internalError("ASR initialization failed: \(error.localizedDescription)")
        }
    }

    /// Transcribe an audio file
    ///
    /// - Parameter path: Path to the audio file (WAV, M4A, MP3, etc.)
    /// - Returns: `AsrResult` containing the transcribed text and metadata
    /// - Throws: `FluidAudioError` if transcription fails
    public func transcribeFile(_ path: String) async throws -> AsrResult {
        guard let manager = asrManager else {
            throw FluidAudioError.notInitialized("ASR not initialized. Call initializeAsr() first")
        }

        let url = URL(fileURLWithPath: path)

        guard FileManager.default.fileExists(atPath: path) else {
            throw FluidAudioError.fileNotFound(path)
        }

        do {
            let result = try await manager.transcribe(url)
            return AsrResult(
                text: result.text,
                confidence: result.confidence,
                duration: result.duration,
                processingTime: result.processingTime,
                rtfx: result.rtfx
            )
        } catch {
            throw FluidAudioError.transcriptionFailed(error.localizedDescription)
        }
    }

    /// Transcribe audio samples directly
    ///
    /// This method accepts raw 16kHz mono audio samples, making it ideal for
    /// real-time audio applications where audio is captured from a microphone
    /// or other streaming source.
    ///
    /// - Parameter samples: Array of f32 audio samples (16kHz mono, normalized to -1.0 to 1.0)
    /// - Returns: `AsrResult` containing the transcribed text and metadata
    /// - Throws: `FluidAudioError` if transcription fails
    ///
    /// ## Example
    /// ```swift
    /// let audio = FluidAudioAPI()
    /// try await audio.initializeAsr()
    ///
    /// // Simulated audio buffer (16kHz mono)
    /// let samples: [Float] = Array(repeating: 0.0, count: 16000) // 1 second
    ///
    /// let result = try await audio.transcribeSamples(samples)
    /// print("Text: \(result.text)")
    /// ```
    public func transcribeSamples(_ samples: [Float]) async throws -> AsrResult {
        guard let manager = asrManager else {
            throw FluidAudioError.notInitialized("ASR not initialized. Call initializeAsr() first")
        }

        do {
            let result = try await manager.transcribe(samples)
            return AsrResult(
                text: result.text,
                confidence: result.confidence,
                duration: result.duration,
                processingTime: result.processingTime,
                rtfx: result.rtfx
            )
        } catch {
            throw FluidAudioError.transcriptionFailed(error.localizedDescription)
        }
    }

    /// Check if ASR is initialized and ready
    public func isAsrAvailable() -> Bool {
        asrManager != nil
    }

    // MARK: - VAD Methods

    /// Initialize the VAD (Voice Activity Detection) engine
    ///
    /// - Parameter threshold: Detection threshold (0.0-1.0, default 0.85)
    /// - Throws: `FluidAudioError` if initialization fails
    public func initializeVad(threshold: Float = 0.85) async throws {
        do {
            let config = VadConfig(defaultThreshold: threshold)
            let manager = try await VadManager(config: config)
            self.vadManager = manager
        } catch {
            throw FluidAudioError.internalError("VAD initialization failed: \(error.localizedDescription)")
        }
    }

    /// Check if VAD is initialized and ready
    public func isVadAvailable() -> Bool {
        vadManager != nil
    }

    // MARK: - Diarization Methods

    /// Initialize the speaker diarization engine
    ///
    /// Downloads and loads the diarization models. First run may take
    /// some time as models are compiled for the Neural Engine.
    ///
    /// - Parameter threshold: Clustering threshold (0.0-1.0, default 0.6).
    ///   Lower values produce more speakers, higher values merge speakers more aggressively.
    /// - Throws: `FluidAudioError` if initialization fails
    public func initializeDiarization(threshold: Double = 0.6) async throws {
        do {
            var config = OfflineDiarizerConfig()
            config.clustering.threshold = threshold
            let manager = OfflineDiarizerManager(config: config)
            try await manager.prepareModels()
            self.diarizerManager = manager
        } catch {
            throw FluidAudioError.internalError("Diarization initialization failed: \(error.localizedDescription)")
        }
    }

    /// Diarize an audio file to identify speaker segments
    ///
    /// - Parameter path: Path to the audio file (WAV, M4A, MP3, etc.)
    /// - Returns: Array of `DiarizationSegment` containing speaker-labeled time segments
    /// - Throws: `FluidAudioError` if diarization fails
    public func diarizeFile(_ path: String) async throws -> [DiarizationSegment] {
        guard let manager = diarizerManager else {
            throw FluidAudioError.notInitialized("Diarization not initialized. Call initializeDiarization() first")
        }

        let url = URL(fileURLWithPath: path)

        guard FileManager.default.fileExists(atPath: path) else {
            throw FluidAudioError.fileNotFound(path)
        }

        do {
            let result = try await manager.process(url)
            return result.segments.map { segment in
                DiarizationSegment(
                    speakerId: segment.speakerId,
                    startTime: segment.startTimeSeconds,
                    endTime: segment.endTimeSeconds,
                    qualityScore: segment.qualityScore
                )
            }
        } catch {
            throw FluidAudioError.processingFailed(error.localizedDescription)
        }
    }

    /// Check if diarization is initialized and ready
    public func isDiarizationAvailable() -> Bool {
        diarizerManager != nil
    }

    // MARK: - System Info

    /// Get system information summary
    ///
    /// Returns a detailed string containing OS version, architecture, chip, cores, memory, and Rosetta status.
    public nonisolated func systemInfo() -> String {
        SystemInfo.summary()
    }

    /// Check if running on Apple Silicon
    public nonisolated var isAppleSilicon: Bool {
        SystemInfo.isAppleSilicon
    }

    /// Check if running on Intel Mac
    public nonisolated var isIntelMac: Bool {
        SystemInfo.isIntelMac
    }

    // MARK: - Cleanup

    /// Release all resources
    public func cleanup() {
        asrManager = nil
        asrModels = nil
        vadManager = nil
        diarizerManager = nil
    }
}

import FluidAudioAPI
import XCTest

final class FluidAudioAPITests: XCTestCase {
    // MARK: - Basic Initialization Tests

    func testInitialization() async throws {
        let audio = FluidAudioAPI()

        // Should not be available before initialization
        let isAvailable1 = await audio.isAsrAvailable(); XCTAssertFalse(isAvailable1)
        let isAvailable2 = await audio.isVadAvailable(); XCTAssertFalse(isAvailable2)
        let isAvailable3 = await audio.isDiarizationAvailable(); XCTAssertFalse(isAvailable3)
    }

    func testSystemInfo() async throws {
        let audio = FluidAudioAPI()

        // System info should work without initialization
        let info = audio.systemInfo()
        XCTAssertFalse(info.isEmpty, "System info should not be empty")
        XCTAssertTrue(info.contains("macOS") || info.contains("iOS"), "Should contain platform name")

        // Architecture checks
        #if arch(arm64)
            XCTAssertTrue(audio.isAppleSilicon, "Should detect Apple Silicon on ARM64")
            XCTAssertFalse(audio.isIntelMac, "Should not detect Intel on ARM64")
        #elseif arch(x86_64)
            XCTAssertFalse(audio.isAppleSilicon, "Should not detect Apple Silicon on x86_64")
            XCTAssertTrue(audio.isIntelMac, "Should detect Intel on x86_64")
        #endif
    }

    // MARK: - Error Handling Tests

    func testAsrNotInitializedError() async throws {
        let audio = FluidAudioAPI()

        // Should throw notInitialized error
        do {
            _ = try await audio.transcribeFile("/tmp/test.wav")
            XCTFail("Should throw error when ASR not initialized")
        } catch let error as FluidAudioError {
            if case .notInitialized = error {
                // Expected error
            } else {
                XCTFail("Expected notInitialized error, got: \(error)")
            }
        }
    }

    func testDiarizationNotInitializedError() async throws {
        let audio = FluidAudioAPI()

        // Should throw notInitialized error
        do {
            _ = try await audio.diarizeFile("/tmp/test.wav")
            XCTFail("Should throw error when diarization not initialized")
        } catch let error as FluidAudioError {
            if case .notInitialized = error {
                // Expected error
            } else {
                XCTFail("Expected notInitialized error, got: \(error)")
            }
        }
    }

    func testFileNotFoundError() async throws {
        #if arch(arm64)
            let audio = FluidAudioAPI()

            // Initialize ASR first
            try await audio.initializeAsr()
            let isAvailable4 = await audio.isAsrAvailable(); XCTAssertTrue(isAvailable4, "ASR should be available after initialization")

            // Try to transcribe non-existent file
            do {
                _ = try await audio.transcribeFile("/tmp/nonexistent_audio_file_12345.wav")
                XCTFail("Should throw error for non-existent file")
            } catch let error as FluidAudioError {
                if case .fileNotFound = error {
                    // Expected error
                } else {
                    XCTFail("Expected fileNotFound error, got: \(error)")
                }
            }
        #else
            throw XCTSkip("ASR requires Apple Silicon")
        #endif
    }

    // MARK: - ASR Tests

    func testAsrInitialization() async throws {
        #if arch(arm64)
            // Only test on Apple Silicon (ASR requires ANE)
            let audio = FluidAudioAPI()

            // Initialize ASR
            try await audio.initializeAsr()

            // Verify it's available
            let isAvailable5 = await audio.isAsrAvailable(); XCTAssertTrue(isAvailable5, "ASR should be available after initialization")
        #else
            throw XCTSkip("ASR requires Apple Silicon")
        #endif
    }

    func testTranscribeSamplesWithSilence() async throws {
        #if arch(arm64)
            // Only test on Apple Silicon
            let audio = FluidAudioAPI()
            try await audio.initializeAsr()

            // Create 1 second of silence (16kHz mono)
            let samples: [Float] = Array(repeating: 0.0, count: 16000)

            // Transcribe silence
            let result = try await audio.transcribeSamples(samples)

            // Verify result structure
            XCTAssertNotNil(result.text, "Result should have text field")
            XCTAssertGreaterThanOrEqual(result.confidence, 0.0, "Confidence should be >= 0")
            XCTAssertLessThanOrEqual(result.confidence, 1.0, "Confidence should be <= 1")
            XCTAssertGreaterThan(result.duration, 0.0, "Duration should be > 0")
            XCTAssertGreaterThan(result.processingTime, 0.0, "Processing time should be > 0")

            // For silence, text should be empty or whitespace
            XCTAssertTrue(
                result.text.trimmingCharacters(in: .whitespaces).isEmpty,
                "Silence should produce empty text, got: '\(result.text)'"
            )

            print("✅ Silence transcription test passed")
            print("   Duration: \(result.duration)s")
            print("   Processing time: \(result.processingTime)s")
            print("   RTF: \(result.rtfx)x")
        #else
            throw XCTSkip("ASR requires Apple Silicon")
        #endif
    }

    // MARK: - VAD Tests

    func testVadInitialization() async throws {
        let audio = FluidAudioAPI()

        // Initialize VAD with default threshold
        try await audio.initializeVad()

        // Verify it's available
        let isAvailable6 = await audio.isVadAvailable(); XCTAssertTrue(isAvailable6, "VAD should be available after initialization")
    }

    func testVadInitializationWithCustomThreshold() async throws {
        let audio = FluidAudioAPI()

        // Initialize VAD with custom threshold
        try await audio.initializeVad(threshold: 0.75)

        // Verify it's available
        let isAvailable7 = await audio.isVadAvailable(); XCTAssertTrue(isAvailable7, "VAD should be available after initialization")
    }

    // MARK: - Diarization Tests

    func testDiarizationInitialization() async throws {
        #if arch(arm64)
            // Only test on Apple Silicon
            let audio = FluidAudioAPI()

            // Initialize diarization with default threshold
            try await audio.initializeDiarization()

            // Verify it's available
            let isAvailable8 = await audio.isDiarizationAvailable(); XCTAssertTrue(isAvailable8, "Diarization should be available after initialization")
        #else
            throw XCTSkip("Diarization requires Apple Silicon")
        #endif
    }

    func testDiarizationInitializationWithCustomThreshold() async throws {
        #if arch(arm64)
            // Only test on Apple Silicon
            let audio = FluidAudioAPI()

            // Initialize diarization with custom threshold
            try await audio.initializeDiarization(threshold: 0.7)

            // Verify it's available
            let isAvailable9 = await audio.isDiarizationAvailable(); XCTAssertTrue(isAvailable9, "Diarization should be available after initialization")
        #else
            throw XCTSkip("Diarization requires Apple Silicon")
        #endif
    }

    // MARK: - Type Tests

    func testAsrResultType() {
        let result = AsrResult(
            text: "test",
            confidence: 0.95,
            duration: 1.5,
            processingTime: 0.3,
            rtfx: 0.2
        )

        XCTAssertEqual(result.text, "test")
        XCTAssertEqual(result.confidence, 0.95)
        XCTAssertEqual(result.duration, 1.5)
        XCTAssertEqual(result.processingTime, 0.3)
        XCTAssertEqual(result.rtfx, 0.2)

        // Verify Sendable conformance compiles
        Task {
            let _ = result
        }
    }

    func testDiarizationSegmentType() {
        let segment = DiarizationSegment(
            speakerId: "SPEAKER_00",
            startTime: 0.0,
            endTime: 5.5,
            qualityScore: 0.88
        )

        XCTAssertEqual(segment.speakerId, "SPEAKER_00")
        XCTAssertEqual(segment.startTime, 0.0)
        XCTAssertEqual(segment.endTime, 5.5)
        XCTAssertEqual(segment.qualityScore, 0.88)
        XCTAssertEqual(segment.duration, 5.5, accuracy: 0.001, "Duration should be 5.5s")

        // Verify Sendable conformance compiles
        Task {
            let _ = segment
        }
    }

    func testFluidAudioError() {
        let error1 = FluidAudioError.notInitialized("ASR not ready")
        XCTAssertTrue(error1.localizedDescription.contains("not initialized"))

        let error2 = FluidAudioError.transcriptionFailed("Failed to transcribe")
        XCTAssertTrue(error2.localizedDescription.contains("Transcription failed"))

        let error3 = FluidAudioError.fileNotFound("/tmp/test.wav")
        XCTAssertTrue(error3.localizedDescription.contains("not found"))

        let error4 = FluidAudioError.processingFailed("Processing error")
        XCTAssertTrue(error4.localizedDescription.contains("Processing failed"))

        let error5 = FluidAudioError.internalError("Internal error")
        XCTAssertTrue(error5.localizedDescription.contains("Internal error"))
    }

    // MARK: - Cleanup Tests

    func testCleanup() async throws {
        #if arch(arm64)
            let audio = FluidAudioAPI()

            // Initialize ASR
            try await audio.initializeAsr()
            let isAvailable10 = await audio.isAsrAvailable(); XCTAssertTrue(isAvailable10)

            // Cleanup
            await audio.cleanup()

            // Should no longer be available
            let isAvailable11 = await audio.isAsrAvailable(); XCTAssertFalse(isAvailable11)
        #else
            throw XCTSkip("ASR requires Apple Silicon")
        #endif
    }
}

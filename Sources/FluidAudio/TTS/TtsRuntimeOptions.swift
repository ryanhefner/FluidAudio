@preconcurrency import CoreML
import Foundation

/// Runtime controls for TTS memory and performance tradeoffs.
///
/// The default value preserves FluidAudio's standard behavior. Apps running in
/// constrained memory environments can opt into ``lowMemory`` or set individual
/// properties without changing the public synthesis APIs.
public struct TtsRuntimeOptions: Sendable {
    public enum KokoroVariantPolicy: Sendable {
        case automatic
        case force(ModelNames.TTS.Variant)
    }

    public var kokoroVariantPolicy: KokoroVariantPolicy
    public var kokoroWarmUpModels: Bool
    public var kokoroMaxConcurrentChunks: Int?
    public var kokoroPreallocatedArrayCount: Int?
    public var kokoroComputeUnits: MLComputeUnits?
    public var pocketTtsComputeUnits: MLComputeUnits?

    public init(
        kokoroVariantPolicy: KokoroVariantPolicy = .automatic,
        kokoroWarmUpModels: Bool = true,
        kokoroMaxConcurrentChunks: Int? = nil,
        kokoroPreallocatedArrayCount: Int? = nil,
        kokoroComputeUnits: MLComputeUnits? = nil,
        pocketTtsComputeUnits: MLComputeUnits? = nil
    ) {
        self.kokoroVariantPolicy = kokoroVariantPolicy
        self.kokoroWarmUpModels = kokoroWarmUpModels
        self.kokoroMaxConcurrentChunks = kokoroMaxConcurrentChunks
        self.kokoroPreallocatedArrayCount = kokoroPreallocatedArrayCount
        self.kokoroComputeUnits = kokoroComputeUnits
        self.pocketTtsComputeUnits = pocketTtsComputeUnits
    }

    public static let `default` = TtsRuntimeOptions()

    public static let lowMemory = TtsRuntimeOptions(
        kokoroVariantPolicy: .force(.fiveSecond),
        kokoroWarmUpModels: false,
        kokoroMaxConcurrentChunks: 1,
        kokoroPreallocatedArrayCount: 1,
        kokoroComputeUnits: .cpuOnly
    )

    internal func effectiveKokoroVariants(
        from requested: [ModelNames.TTS.Variant]
    ) -> [ModelNames.TTS.Variant] {
        switch kokoroVariantPolicy {
        case .automatic:
            return requested
        case .force(let variant):
            return [variant]
        }
    }

    internal var effectiveKokoroMaxConcurrentChunks: Int? {
        guard let kokoroMaxConcurrentChunks else { return nil }
        return max(1, kokoroMaxConcurrentChunks)
    }

    internal var effectiveKokoroPreallocatedArrayCount: Int? {
        guard let kokoroPreallocatedArrayCount else { return nil }
        return max(1, kokoroPreallocatedArrayCount)
    }
}

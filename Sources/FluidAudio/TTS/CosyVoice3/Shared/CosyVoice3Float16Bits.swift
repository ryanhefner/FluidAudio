import Foundation

enum CosyVoice3Float16Bits {
    static func float32(from bits: UInt16) -> Float {
        let sign = UInt32(bits & 0x8000) << 16
        let exponent = UInt32((bits >> 10) & 0x1f)
        let fraction = UInt32(bits & 0x03ff)

        if exponent == 0 {
            guard fraction != 0 else {
                return Float(bitPattern: sign)
            }

            var normalizedFraction = fraction
            var normalizedExponent = -14
            while (normalizedFraction & 0x0400) == 0 {
                normalizedFraction <<= 1
                normalizedExponent -= 1
            }
            normalizedFraction &= 0x03ff
            let exponentBits = UInt32(normalizedExponent + 127) << 23
            return Float(bitPattern: sign | exponentBits | (normalizedFraction << 13))
        }

        if exponent == 0x1f {
            let payload = fraction << 13
            if payload == 0 {
                return Float(bitPattern: sign | 0x7f80_0000)
            }
            return Float(bitPattern: sign | 0x7f80_0000 | payload | 0x0040_0000)
        }

        let exponentBits = (exponent + 112) << 23
        return Float(bitPattern: sign | exponentBits | (fraction << 13))
    }
}

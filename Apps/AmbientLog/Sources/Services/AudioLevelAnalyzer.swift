import Foundation

enum AudioLevelAnalyzer {
    static let minimumPower: Double = -160
    static let maximumPower: Double = 0
    static let silence = minimumPower

    static func normalizePower(_ power: Double) -> Double {
        let clamped = min(max(power, minimumPower), maximumPower)
        return (clamped - minimumPower) / (maximumPower - minimumPower)
    }

    static func averagePower(_ powers: [Double]) -> Double {
        guard !powers.isEmpty else { return silence }
        return powers.reduce(0, +) / Double(powers.count)
    }

    static func peakPower(_ powers: [Double]) -> Double {
        powers.max() ?? silence
    }

    static func downsample(_ powers: [Double], maximumPoints: Int = 120) -> [Double] {
        guard powers.count > maximumPoints else { return powers }
        let bucketSize = Double(powers.count) / Double(maximumPoints)
        return (0 ..< maximumPoints).map { index in
            let start = Int(floor(Double(index) * bucketSize))
            let end = min(powers.count, Int(floor(Double(index + 1) * bucketSize)))
            let bucket = powers[range(start, end)]
            return bucket.max() ?? silence
        }
    }

    private static func range(_ start: Int, _ end: Int) -> Range<Int> {
        max(0, start) ..< max(0, end)
    }
}

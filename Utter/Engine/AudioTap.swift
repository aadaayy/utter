import AVFoundation
import Speech

/// Runs on the audio thread: converts each mic buffer to the speech engine's
/// format and passes it on, and keeps the latest loudness for the ring.
/// The target can be swapped (switching language) without stopping the mic.
final class AudioTap: @unchecked Sendable {
    private let lock = NSLock()
    private var converter: AVAudioConverter?
    private var targetFormat: AVAudioFormat?
    private var continuation: AsyncStream<AnalyzerInput>.Continuation?
    private var latestLevel: Double = 0

    func route(to continuation: AsyncStream<AnalyzerInput>.Continuation?, format: AVAudioFormat?) {
        lock.lock()
        self.continuation = continuation
        targetFormat = format
        converter = nil
        lock.unlock()
    }

    /// Loudness from 0 to 1, smoothed a little.
    var level: Double {
        lock.lock(); defer { lock.unlock() }
        return latestLevel
    }

    func feed(_ buffer: AVAudioPCMBuffer) {
        let loudness = Self.loudness(of: buffer)
        lock.lock()
        latestLevel = max(loudness, latestLevel * 0.8)
        guard let continuation, let targetFormat else { lock.unlock(); return }
        if converter == nil || converter?.inputFormat != buffer.format {
            converter = AVAudioConverter(from: buffer.format, to: targetFormat)
        }
        let converter = self.converter
        lock.unlock()

        guard let converter else { return }
        if buffer.format == targetFormat {
            continuation.yield(AnalyzerInput(buffer: buffer))
            return
        }
        let ratio = targetFormat.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 16
        guard let output = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: capacity) else { return }
        var handedOver = false
        var error: NSError?
        converter.convert(to: output, error: &error) { _, status in
            if handedOver {
                status.pointee = .noDataNow
                return nil
            }
            handedOver = true
            status.pointee = .haveData
            return buffer
        }
        if error == nil, output.frameLength > 0 {
            continuation.yield(AnalyzerInput(buffer: output))
        }
    }

    static func loudness(of buffer: AVAudioPCMBuffer) -> Double {
        guard let samples = buffer.floatChannelData?[0], buffer.frameLength > 0 else { return 0 }
        let count = Int(buffer.frameLength)
        var sum: Float = 0
        for index in 0..<count { sum += samples[index] * samples[index] }
        let rms = sqrt(sum / Float(count))
        // About -50 dB is quiet, -10 dB is loud talking.
        let decibels = 20 * log10(max(rms, 0.000_01))
        return Double(min(1, max(0, (decibels + 50) / 40)))
    }
}

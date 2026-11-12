import AVFoundation
import Speech

/// The two permissions Utter asks for: the microphone, and speech recognition.
enum Permissions {
    enum Status { case notAsked, allowed, denied }

    static var microphone: Status {
        switch AVAudioApplication.shared.recordPermission {
        case .granted: return .allowed
        case .denied: return .denied
        default: return .notAsked
        }
    }

    static func requestMicrophone() async -> Bool {
        if microphone == .allowed { return true }
        return await AVAudioApplication.requestRecordPermission()
    }

    static var speech: Status {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized: return .allowed
        case .denied, .restricted: return .denied
        default: return .notAsked
        }
    }

    static func requestSpeech() async -> Bool {
        if speech == .allowed { return true }
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
}

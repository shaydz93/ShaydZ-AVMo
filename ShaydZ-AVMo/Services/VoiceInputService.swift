import Foundation
import Speech
import AVFoundation
import Combine

/// Service for handling voice input and speech recognition
@MainActor
class VoiceInputService: NSObject, ObservableObject {
    static let shared = VoiceInputService()
    
    // MARK: - Published Properties
    @Published var isRecording = false
    @Published var isPermissionGranted = false
    @Published var transcribedText = ""
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    
    private override init() {
        super.init()
        setupSpeechRecognizer()
    }
    
    // MARK: - Public Methods
    
    /// Request permission for speech recognition and microphone access
    func requestPermissions() async -> Bool {
        let speechPermission = await requestSpeechPermission()
        let microphonePermission = await requestMicrophonePermission()
        
        let granted = speechPermission && microphonePermission
        isPermissionGranted = granted
        return granted
    }
    
    /// Start voice recording and speech recognition
    func startRecording() async {
        guard isPermissionGranted else {
            errorMessage = "Permissions not granted for speech recognition"
            return
        }
        
        guard !isRecording else { return }
        
        do {
            try await startSpeechRecognition()
            isRecording = true
            errorMessage = nil
        } catch {
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
        }
    }
    
    /// Stop voice recording
    func stopRecording() {
        guard isRecording else { return }
        
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }
    
    /// Toggle recording state
    func toggleRecording() async {
        if isRecording {
            stopRecording()
        } else {
            await startRecording()
        }
    }
    
    /// Clear transcribed text
    func clearText() {
        transcribedText = ""
    }
    
    /// Check if speech recognition is available
    var isSpeechRecognitionAvailable: Bool {
        return speechRecognizer?.isAvailable ?? false
    }
    
    // MARK: - Private Methods
    
    private func setupSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        speechRecognizer?.delegate = self
    }
    
    private func requestSpeechPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    private func requestMicrophonePermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    private func startSpeechRecognition() async throws {
        // Cancel any previous task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw VoiceInputError.recognitionRequestFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Create audio input node
        let inputNode = audioEngine.inputNode
        
        // Create recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                if let result = result {
                    self?.transcribedText = result.bestTranscription.formattedString
                    
                    if result.isFinal {
                        self?.stopRecording()
                    }
                }
                
                if let error = error {
                    self?.errorMessage = "Recognition error: \(error.localizedDescription)"
                    self?.stopRecording()
                }
            }
        }
        
        // Configure audio format
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()
    }
}

// MARK: - SFSpeechRecognizerDelegate
extension VoiceInputService: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if !available {
            stopRecording()
            errorMessage = "Speech recognition is not available"
        }
    }
}

// MARK: - Voice Input Error
enum VoiceInputError: Error, LocalizedError {
    case recognitionRequestFailed
    case permissionDenied
    case audioEngineFailure
    
    var errorDescription: String? {
        switch self {
        case .recognitionRequestFailed:
            return "Failed to create speech recognition request"
        case .permissionDenied:
            return "Permission denied for speech recognition or microphone access"
        case .audioEngineFailure:
            return "Audio engine failed to start"
        }
    }
}

// MARK: - Voice Command Processing
extension VoiceInputService {
    /// Process transcribed text for voice commands
    func processVoiceCommand(_ text: String) -> VoiceCommand? {
        let lowercaseText = text.lowercased()
        
        // App recommendation commands
        if lowercaseText.contains("recommend") || lowercaseText.contains("suggest") {
            if lowercaseText.contains("app") || lowercaseText.contains("application") {
                return .recommendApps
            }
        }
        
        // VM management commands
        if lowercaseText.contains("virtual machine") || lowercaseText.contains("vm") {
            if lowercaseText.contains("status") || lowercaseText.contains("check") {
                return .checkVMStatus
            }
            if lowercaseText.contains("optimize") || lowercaseText.contains("performance") {
                return .optimizeVM
            }
        }
        
        // Navigation commands
        if lowercaseText.contains("open") || lowercaseText.contains("show") {
            if lowercaseText.contains("app library") || lowercaseText.contains("apps") {
                return .openAppLibrary
            }
            if lowercaseText.contains("settings") {
                return .openSettings
            }
            if lowercaseText.contains("analytics") || lowercaseText.contains("dashboard") {
                return .openAnalytics
            }
        }
        
        // Help commands
        if lowercaseText.contains("help") || lowercaseText.contains("what can you do") {
            return .help
        }
        
        return .unknown(text)
    }
}

// MARK: - Voice Command Enum
enum VoiceCommand {
    case recommendApps
    case checkVMStatus
    case optimizeVM
    case openAppLibrary
    case openSettings
    case openAnalytics
    case help
    case unknown(String)
    
    var aiChatMessage: String {
        switch self {
        case .recommendApps:
            return "Recommend some apps for me"
        case .checkVMStatus:
            return "What's my VM status?"
        case .optimizeVM:
            return "How can I optimize my VM performance?"
        case .openAppLibrary:
            return "Open the app library"
        case .openSettings:
            return "Open settings"
        case .openAnalytics:
            return "Show me the analytics dashboard"
        case .help:
            return "What can you help me with?"
        case .unknown(let text):
            return text
        }
    }
}
import Foundation
import AVFoundation
import Speech

@objc public class TranscriptionController: NSObject {
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @objc public var transcriptionCallback: ((String) -> Void)?
    @objc public var transcriptionDoneCallback: ((String) -> Void)?
    
    @objc public var isRecording = false
    
    public override init() {
        super.init()
    }
    
    @objc public func startRecording() {
        
        isRecording = true
        if audioEngine.isRunning {
                self.stopRecording()
        }
        // Cancel the previous task if it's running.
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }

        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        let inputNode = audioEngine.inputNode

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Ensure on-device recognition if possible.
        if #available(iOS 13, *) {
            recognitionRequest.requiresOnDeviceRecognition = true
        }

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            if !self.isRecording {
                return
            }
            var isSessionEnd = false
            
            if let result = result {
                let transcription = result.bestTranscription.formattedString
                isSessionEnd = result.isFinal
                let finalResult = result.bestTranscription.segments[0].confidence > 0.0 ? true : false
                self.transcriptionCallback?(transcription)
                
                if finalResult {
                    self.transcriptionDoneCallback?(transcription)
                }
            }

            if error != nil || isSessionEnd {
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        }
        
        // Configure the microphone input.
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try! audioEngine.start()
    }
    
    @objc public func stopRecording() {
        isRecording = false
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
    }
}

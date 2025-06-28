// 4 дз
//  SpeechRecognizer.swift
//  MoneyDetector
//
//  Created by mac on 28.06.2025.
//
import SwiftUI
import Combine
import Speech


final class SpeechRecognizer: ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ru-RU"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    init() {
        SFSpeechRecognizer.requestAuthorization { _ in }
        AVAudioSession.sharedInstance().requestRecordPermission { _ in }
    }
    
    func toggleRecording() {
        if audioEngine.isRunning {
            stopRecording()
        } else {
            startRecording()
        }
        DispatchQueue.main.async {
            self.isRecording.toggle()
        }
    }
    func startRecording() {
        recognitionTask?.cancel()
        recognitionTask = nil
        transcript = ""
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? session.setActive(true, options: .notifyOthersOnDeactivation)
        request = SFSpeechAudioBufferRecognitionRequest()
        request?.shouldReportPartialResults = true
        
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request!) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                DispatchQueue.main.async {
                    self.transcript = result.bestTranscription.formattedString
                }
            }
            if error != nil || result?.isFinal == true {
                self.stopRecording()
                DispatchQueue.main.async {
                    self.isRecording = false
                }
            }
        }
        
       
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            self.request?.append(buffer)
        }
        
        audioEngine.prepare()
        try? audioEngine.start()

    }
    func stopRecording() {
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        recognitionTask?.cancel()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            
    }
}

struct Article: Identifiable, Hashable {
    let id: Int
    let title: String
    let icon: String
}

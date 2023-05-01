//
//  AudioAnalyzer.swift
//  MetalCircle
//
//  Created by Nhan Tran on 4/30/23.
//


// TODO: refactor this so both SphereDeformableView and AudioVisualizer can share it. Then we can reduce code duplication because the audio analysis should be similar between the two. Note that this is not tested yet.
import Foundation

import AVFoundation

class AudioAnalyzer {
    private var audioEngine = AVAudioEngine()
    private var audioBuffer: AVAudioPCMBuffer
    private var audioFile: AVAudioFile?
    private var audioPlayerNode = AVAudioPlayerNode()
    
    var onUpdate: (([Float]) -> Void)?
    
    init() {
        let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)
        audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat!, frameCapacity: 1024)!
    }
    
    func start(audioURL: URL? = nil) {
        if let url = audioURL {
            do {
                audioFile = try AVAudioFile(forReading: url)
            } catch {
                print("Error reading audio file: \(error)")
                return
            }
        } else {
            guard let url = Bundle.main.url(forResource: "example", withExtension: "mp3") else {
                print("Error finding audio file in the bundle")
                return
            }
            do {
                audioFile = try AVAudioFile(forReading: url)
            } catch {
                print("Error reading audio file: \(error)")
                return
            }
        }
        
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        
        let mixerNode = AVAudioMixerNode()
        audioEngine.attach(mixerNode)
        audioEngine.connect(audioPlayerNode, to: mixerNode, format: audioFile!.processingFormat)
        audioEngine.connect(mixerNode, to: audioEngine.mainMixerNode, format: format)
        
        mixerNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] (buffer, time) in
            guard let strongSelf = self else { return }
            let channelCount = Int(buffer.format.channelCount)
            let frameLength = Int(buffer.frameLength)
            var data = [Float]()
            
            for i in 0..<channelCount {
                let samples = buffer.floatChannelData?[i]
                for j in 0..<frameLength {
                    let sample = samples?[j]
                    data.append(sample!)
                }
            }
            
            DispatchQueue.main.async {
                strongSelf.onUpdate?(data)
            }
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            audioPlayerNode.scheduleFile(audioFile!, at: nil, completionHandler: nil)
            audioPlayerNode.play()
        } catch {
            print("Error starting audio engine: \(error)")
        }
    }
    
    func stop() {
        audioEngine.stop()
        audioEngine.reset()
    }
}

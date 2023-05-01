//
//  AudioVisualizerView.swift
//  MetalCircle
//
//  Created by Nhan Tran on 4/30/23.
//

import Foundation
import MetalKit
import SwiftUI

struct AudioVisualizerView: UIViewRepresentable {
    @Environment(\.presentationMode) private var presentationMode

    func makeCoordinator() -> AudioVisualizer {
        let mtkView = MTKView()
        
        mtkView.preferredFramesPerSecond = 60
        mtkView.isPaused = true
        mtkView.enableSetNeedsDisplay = false
        
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            mtkView.device = metalDevice
        }
        mtkView.framebufferOnly = false
        mtkView.drawableSize = mtkView.frame.size
        
        let coordinator = AudioVisualizer(mtkView: mtkView)
        mtkView.delegate = coordinator
        
        return coordinator
    }
    
    func makeUIView(context: UIViewRepresentableContext<AudioVisualizerView>) -> MTKView {
        return context.coordinator.mtkview
    }
    
    // Clean up resources when view is dismissed (so audio stuff will be reset)
    func updateUIView(_ uiView: MTKView, context: UIViewRepresentableContext<AudioVisualizerView>) {
        if presentationMode.wrappedValue.isPresented == false {
            context.coordinator.stopAudio()
        } else {
            context.coordinator.startAudio()
        }
    }
}

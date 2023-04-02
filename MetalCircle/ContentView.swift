//
//  ContentView.swift
//  MetalCircle
//
//  Created by Nhan Tran on 4/2/23.
//

import SwiftUI
import MetalKit

struct ContentView: UIViewRepresentable {
    
    func makeCoordinator() -> MetalCircleView {
        MetalCircleView(self)
    }
    
    func makeUIView(context: UIViewRepresentableContext<ContentView>) -> MTKView {
        let mtkView = MTKView()
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = true
        
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            mtkView.device = metalDevice
        }
        
        mtkView.framebufferOnly = false
        mtkView.drawableSize = mtkView.frame.size
        
        return mtkView
    }
    
    
    func updateUIView(_ uiView: MTKView, context: UIViewRepresentableContext<ContentView>) {
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().edgesIgnoringSafeArea(.all)
    }
}

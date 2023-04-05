//
//  ContentView.swift
//  MetalCircle
//
//  Created by Nhan Tran on 4/2/23.
//

import SwiftUI
import MetalKit

/*
 UIViewRepresentable is a protocol in SwiftUI that allows you to create a SwiftUI
 view that represents a UIKit view, in this case, MTKView.
 This is necessary because MTKView is a UIKit class,
 and SwiftUI doesn't have a native view for Metal rendering.
 */
struct ContentView: UIViewRepresentable {
    
    func makeCoordinator() -> AudioVisualizer {
        /**
         This function is responsible for creating a coordinator object,
         which is used to manage the communication between our SwiftUI view and the UIKit view.
         The coordinator conforms to the MTKViewDelegate protocol.
         The coordinator is an intermediary that helps SwiftUI and UIKit work together
         */
        let mtkView = MTKView()
        
        /**
         Delegate is a design pattern in which an object "delegates"
         some of its responsibilities to another object. In this case,
         the 'MTKView' delegates its drawing responsibility to our
         `AudioVisualizer` instance (the coordinator).
         By setting `mtkView.delegate = context.coordinator`,
         we're telling the `MTKView`to call the drawing methods on our
         `AudioVisualizer` instance.
         */
        mtkView.preferredFramesPerSecond = 60
        /**
         When view.enableSetNeedsDisplay=true, the view
         will only redraw itself when we manually call
         setNeedsDisplay() in the code.
         For example:
         1. When we want to render on-demand or in response to specific events,
         rather than continuously rendering frames. Useful when the content
         of the view changes infrequently, and we want to save power/processing resources
         2. When we want to update the view at irregular interval
         3. When we're synchrononizing our rendering with other proceses/events in our app
         and we need to ensure that rendering only occurs at specific moments.
         */
        //mtkView.enableSetNeedsDisplay = true
        
        //updates
        mtkView.isPaused = true
        mtkView.enableSetNeedsDisplay = false
        
        // connect to GPU
        if let metalDevice = MTLCreateSystemDefaultDevice()
        {
            mtkView.device = metalDevice
        }
        mtkView.framebufferOnly = false
        mtkView.drawableSize = mtkView.frame.size
        
        let coordinator = AudioVisualizer(self, mtkView: mtkView)
        mtkView.delegate = coordinator
        
        return coordinator
    }
    
    func makeUIView(context: UIViewRepresentableContext<ContentView>) -> MTKView {
        /**
         This function creates an MTKView instance that will be used for Metal Rendering
         Context is a reference to the coordinator created in `makeCoordinator()`
         The `context.coordinator` is used to access our custom coordinate
         (the instance `AudioVisualizer`
         */

        return context.coordinator.mtkview
    }
    
    
    func updateUIView(_ uiView: MTKView, context: UIViewRepresentableContext<ContentView>) {
        /**
         Called when SwiftUI view needs to update the underlying `MTKView`.
         There's no need to update the view so it can be empty for now
         */
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().edgesIgnoringSafeArea(.all)
    }
}

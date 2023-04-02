//
//  MetalCircleView.swift
//  MetalCircle
//
//  Created by Nhan Tran on 4/2/23.
//

import MetalKit

class MetalCircleView: NSObject, MTKViewDelegate {
    var parent: ContentView
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!
    
    init (_ parent: ContentView) {
        self.parent = parent
        if let metalDevice = MTLCreateSystemDefaultDevice()  {
            self.metalDevice = metalDevice
        }
        //creating the command queue
        self.metalCommandQueue = metalDevice.makeCommandQueue()
        super.init()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {

    }
    
    func draw(in view: MTKView) {
        //Creating the commandBuffer for the queue
        guard let commandBuffer  = metalCommandQueue.makeCommandBuffer() else {return}
        
        // Create the interface for the pipeline
        guard let renderDescriptor = view.currentRenderPassDescriptor else {return}
        // Setting a background color
        renderDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0,0,1,1)
        // Creating the command encoder, or the "inside" of the pipeline
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderDescriptor)
        else {return}
        
        renderEncoder.endEncoding()
        
        // Tell the GPU where to send the rendered result.
        // a drawable representing the current frame
        // A MTLDrawable is a “displayable resource that can be rendered or written to.
        commandBuffer.present(view.currentDrawable!)
        
        // Add the instruction to our metalCommandQueue
        commandBuffer.commit()


        
        
    }
}


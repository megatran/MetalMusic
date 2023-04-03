//
//  AudioVisualizer.swift
//  MetalCircle
//
//  Created by Nhan Tran on 4/3/23.
//

import MetalKit
import AVFoundation

class AudioVisualizer: NSObject, MTKViewDelegate {
    var parent: ContentView
    var mtkview: MTKView
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!
    
    // Vertices of the circle
    var circleVertices = [simd_float2]()
    private var vertexBuffer : MTLBuffer!


    private var metalRenderPipelineState : MTLRenderPipelineState!

    
    /**
        Audio procesing references
     **/
    var engine: AVAudioEngine!
    
    init (_ parent: ContentView, mtkView: MTKView) {
        self.parent = parent
        self.mtkview = mtkView
        self.metalDevice = mtkview.device

        //creating the command queue
        self.metalCommandQueue = metalDevice.makeCommandQueue()
    
        super.init()
       
        //creating the render pipeline state
        self.createPipelineState(mtkview: mtkview)
        self.createVertexPoints()
        
        // takes “length” number of bytes from our circleVertices and stores it into GPU/CPU accessible memory.
        vertexBuffer = metalDevice.makeBuffer(bytes: circleVertices, length: circleVertices.count * MemoryLayout<simd_float2>.stride, options:[])!
        
        /*
            Setup audio processing in our view
         */
        self.setupAudio() 
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {

    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable else {
            return
        }
        
        //Creating the commandBuffer for the queue
        guard let commandBuffer  = metalCommandQueue.makeCommandBuffer() else {return}
        
        // Create the interface for the pipeline
        guard let renderDescriptor = view.currentRenderPassDescriptor else {return}
        // Setting a background color
        renderDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0,0,1,1)
        
        // Creating the command encoder, or the "inside" of the pipeline
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderDescriptor)
        else {return}
        
        
        renderEncoder.setRenderPipelineState(metalRenderPipelineState)
        
        /*********** Encoding the commands **************/
        // ensure that the x,y coordinates of the vertices are scaled proportionally with
        // respect to the window or screensize
        // passing this value into our shader entures that the circle maintains
        // its shape and doesn't get stretched when the window size changes.
        var aspectRatio = Float(view.drawableSize.width / view.drawableSize.height)
        renderEncoder.setVertexBytes(&aspectRatio, length: MemoryLayout<Float>.size, index: 1)

        
        // Match the [[buffer(index 0)]]  attribute in the vertex shader
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        /*
         You may be wondering why we need to specify vertexStart point and vertexCount point. This is needed when you want to create different primitive types in the same render pass. If your first 1000 vertexes are for triangles and the next 1000 are for lines, you will want to specify from what vertex does the next primitive type start.
         
         We have 1081 vertex points and we want to render triangles from the very first point.
         Also, a Triangle Strip is a set of connected triangles which share vertices.
         Diff
            - triangle — rasterizes a triangle for every separate triplet of points
            - triangleStrip — rasterizes a triangle for every three adjacent triplet of points
         */
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 1081)
        renderEncoder.endEncoding()
        
        // Tell the GPU where to send the rendered result.
        // a drawable representing the current frame
        // A MTLDrawable is a “displayable resource that can be rendered or written to.
        commandBuffer.present(drawable)
        
        // Add the instruction to our metalCommandQueue
        commandBuffer.commit()
    }
    
    private func createVertexPoints() {
        func to_radian(forDegree d: Float) -> Float32 {
            return (Float.pi * d)/180
        }
        let origin = simd_float2(0, 0)
        
        for i in 0...720 {
            let x = cos(to_radian(forDegree: Float(Float(i)/2.0)))
            let y = sin(to_radian(forDegree: Float(Float(i)/2.0)))
            let position: simd_float2 = [x,y]
            circleVertices.append(position)
            
            // In between every two perimeter points, we need to form a triangle with the origin
            if (i+1) % 2 == 0 {
                circleVertices.append(origin)
            }
        }
    }
    
    fileprivate func createPipelineState(mtkview: MTKView){
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        
        // finds the Metal file from the main bundle
        let library = metalDevice.makeDefaultLibrary()
        
        // give the names of the function to the pipelineDescriptor
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertexShader")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragmentShader")
        
        // Tell the pipeline descriptor in what format to store the pixel data.
        // set the pixel format to match the MetalView's pixel format
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkview.colorPixelFormat
        
        // make the pipeline state use the GPU interface and the pipeline descriptor
        metalRenderPipelineState = try! metalDevice.makeRenderPipelineState(descriptor: pipelineDescriptor)
        
    }
    
    func setupAudio() {
        engine = AVAudioEngine()
        
        //initialzing the mainMixerNode singleton which will connect to the default output node
        _ = engine.mainMixerNode
        
        //prepare and start
        engine.prepare()
        do {
            try engine.start()
        } catch {
            print(error)
        }
        
        // Add a player node (our music) to the engine
        guard let url = Bundle.main.url(forResource: "breath_of_life_by_florence_and_the_machine", withExtension: "mp3") else {
            print("mp3 not found")
            return
        }
        
        let player = AVAudioPlayerNode()
        
        do {
            let audioFile = try AVAudioFile(forReading: url)
            let format = audioFile.processingFormat
            
            /**
             Recall that the mainMixerNode connects to the default outputNode
             We need to "attach" our node to the engine before connecting it
             to the mainMixerNode.
             */
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            
            // Let's play the file
            player.scheduleFile(audioFile, at: nil, completionHandler: nil)
        } catch {
            print(error.localizedDescription)
        }
        
        // Start playing the music
        player.play()
        
        
    }
}


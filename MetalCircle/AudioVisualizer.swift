//
//  AudioVisualizer.swift
//  MetalCircle
//
//  Created by Nhan Tran on 4/3/23.
//

import MetalKit
import AVFoundation
import Accelerate

class AudioVisualizer: NSObject, MTKViewDelegate {
    var parent: ContentView
    var mtkview: MTKView
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!
    
   /**
    Vertices of the circle
    SIMD library is to ensure the data is being represented consistently in memory across the CPU and the GPU as the library exists for both Swift and Metal.
    **/
    var circleVertices = [simd_float2]()
    private var vertexBuffer : MTLBuffer!
    
    
    // In shader, a uniform variable is a constant value that is applied to all vertices uniformly
    private var loudnessUniformBuffer: MTLBuffer!
    public var loudnessMagnitude: Float = 0.3 {
        /*
         When the value of the loudnessMagnitude property is changed, the didSet observer is triggered and it updates the loudnessUniformBuffer buffer with the new value of loudnessMagnitude.
         */
        didSet {
            loudnessUniformBuffer = metalDevice.makeBuffer(bytes: &loudnessMagnitude, length: MemoryLayout<Float>.stride, options: [])!
            mtkview.draw()
        }
    }
    
    private var frequencyBuffer: MTLBuffer!
    public var frequencyVertices: [Float]  = [Float](repeating: 0, count: 361) {
        didSet {
            let sliced = Array(frequencyVertices[76..<438])
            frequencyBuffer = metalDevice.makeBuffer(bytes: sliced, length: sliced.count * MemoryLayout<Float>.stride, options: [])!
                mtkview.draw()
        }
    }

    private var aspectRatio: Float = 1.0

    private var metalRenderPipelineState : MTLRenderPipelineState!

    
    /**
        Audio procesing references
     **/
    var engine: AVAudioEngine!
    var prevRMSValue : Float = 0.3
    //fft setup object for 1024 values going forward (time domain -> frequency domain)
    let fftSetup = vDSP_DFT_zop_CreateSetup(nil, 1024, vDSP_DFT_Direction.FORWARD)

    
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
        
        loudnessUniformBuffer = metalDevice.makeBuffer(bytes: &loudnessMagnitude, length: MemoryLayout<Float>.stride, options: [])!
        
        frequencyBuffer = metalDevice.makeBuffer(bytes: frequencyVertices, length: frequencyVertices.count * MemoryLayout<Float>.stride, options: [])!
        
        // TODO(nhan): investigate whether we need this
        //mtkview.setNeedsDisplay()
        mtkview.draw()
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
        renderDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0,0,0,1)
        
        // Creating the command encoder, or the "inside" of the pipeline
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderDescriptor)
        else {return}
        
        
        renderEncoder.setRenderPipelineState(metalRenderPipelineState)
        
        /*********** Encoding the commands **************/
        
        // Match the [[buffer(index 0)]]  attribute in the vertex shader
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        renderEncoder.setVertexBuffer(loudnessUniformBuffer, offset: 0, index: 1)
        
        renderEncoder.setVertexBuffer(frequencyBuffer, offset: 0, index: 2)
        
        // ensure that the x,y coordinates of the vertices are scaled proportionally with
        // respect to the window or screensize
        // passing this value into our shader entures that the circle maintains
        // its shape and doesn't get stretched when the window size changes.
        aspectRatio = Float(view.drawableSize.width / view.drawableSize.height)
        renderEncoder.setVertexBytes(&aspectRatio, length: MemoryLayout<Float>.stride, index: 3)

        
        
        /*
         You may be wondering why we need to specify vertexStart point and vertexCount point. This is needed when you want to create different primitive types in the same render pass. If your first 1000 vertexes are for triangles and the next 1000 are for lines, you will want to specify from what vertex does the next primitive type start.
         
         We have 1081 vertex points and we want to render triangles from the very first point.
         Also, a Triangle Strip is a set of connected triangles which share vertices.
         Diff
            - triangle — rasterizes a triangle for every separate triplet of points
            - triangleStrip — rasterizes a triangle for every three adjacent triplet of points
         
         The drawPrimitives called with a vertexCount of 1081, which triggers the vertex function in our shader to run 1081 times with a vertex_id(vid) from 0 to 1080.
         */
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 1081)
        
        renderEncoder.drawPrimitives(type: .lineStrip, vertexStart: 1081, vertexCount: 1081)
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
            
            /**
             Format  <AVAudioFormat 0x600002fc6710:  2 ch,  48000 Hz, Float32, deinterleaved>
             The audio was sampled at 48000 Hz and the amplitude of hte audio frames is represented by a 32-bit float
             The last property  interleaving refers to the way audio data is stored in memory.
             For example, in a stereo audio buffer with 16 samples, the first sample in the buffer is the first sample from the left channel, the second sample is the first sample from the right channel, the third sample is the second sample from the left channel, etc.
             L1 R1 L2 R2 L3 R3 L4 R4 L5 R5 L6 R6 L7 R7 L8 R8

             On the other hand, deinterleaved audio data means that each channel is stored in a separate buffer. So, in our stereo audio example, instead of having a single buffer with 16 samples, you would have two separate buffers, one for the left channel with 8 samples and one for the right channel with 8 samples.
             Deinterleaved stereo audio buffer with 8 samples each:

             Left channel buffer:
             L1 L2 L3 L4 L5 L6 L7 L8

             Right channel buffer:
             R1 R2 R3 R4 R5 R6 R7 R8
             */
            // print("Format ", format)

            // Let's play the file
            player.scheduleFile(audioFile, at: nil, completionHandler: nil)
        } catch {
            print("ERROR: ", error.localizedDescription)
        }
        
        /**
         Tap it to get the buffer data at playtime
         Installs an audio tap on the bus to record, monitor, and observe the output of the node.
         - onBus — describes which output bus you want to fetch the data from
         - bufferSize — describes the number of bytes you want back from the audio data.
         - format — nil for our purposes, it will figure it out itself
         - block — this is the data passed in the callback consisting of an AVAudioPCMBuffer and AVAudioTime (time the track is at)
                    The tapBlock may be invoked on a thread other than the main thread.
         */
         // TODO(nhan): there's a known bug in here... the buffer size might not be correct
         // I'm setting it to 9000 so that the song doesn't end too soon...
         // Sometimes when the app is running, the audio becomes choppy then returns to normal...
        engine.mainMixerNode.installTap(onBus: 0, bufferSize: 9000, format: nil) { (buffer, time) in
            self.processAudioData(buffer: buffer)
        }
        // Start playing the music
        player.play()
    }
    
    func processAudioData(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else {return}
        let frames = buffer.frameLength
        print("frameLength: ", frames)
        
        let rmsValue = SignalProcessing.RootMeanSquare(data: channelData, frameLength: UInt(frames))
        
        print("RMS: ", rmsValue)

        let interpolatedResults = SignalProcessing.linearInterpolate(current: rmsValue, previous: prevRMSValue)
        prevRMSValue = rmsValue
        
        // Pass values for rendering
        for rms in interpolatedResults {
            loudnessMagnitude = rms
        }
        
        //fft
        let fftMagnitudes =  SignalProcessing.fft(data: channelData, setup: fftSetup!)
        frequencyVertices = fftMagnitudes
    }
}


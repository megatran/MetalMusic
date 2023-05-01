//
//  SphereDeformableView.swift
//  MetalCircle
//
//  Created by Nhan Tran on 4/30/23.
//

import SwiftUI
import SceneKit


struct SphereDeformable: View {
    @State private var zTranslation: Float = 0
    @State private var translationsData: NSData = NSData()
    @State private var verticesCount: Int = 0
    
    @State private var isAnimating: Bool = false
    @State private var originalVertexPositions: [Float] = []
    
    let scene = SCNScene()
    private var sphereNode = SCNNode(geometry: SCNSphere(radius: 1))
    
    var body: some View {
        VStack {
            SceneView(scene: scene, options: [.allowsCameraControl], preferredFramesPerSecond: 60, antialiasingMode: .multisampling4X, delegate: nil)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
            
            Button(action: {
                isAnimating.toggle()
                if isAnimating {
                    startAnimation()
                } else {
                    stopAnimation()
                }
            }) {
                Text(isAnimating ? "Stop" : "Animate")
            }
        }
        .onAppear {
            setupScene()
            //startAnimation()
        }
    }
    
    
    private func setupScene() {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 5)
        scene.rootNode.addChildNode(cameraNode)
        
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        sphereNode.position = SCNVector3(x: 0, y: 0, z: 0)
        
        // Set up wireframe material
        sphereNode.geometry?.firstMaterial?.fillMode = .lines

        
        scene.rootNode.addChildNode(sphereNode)
        
        verticesCount = (sphereNode.geometry!.sources.first?.data.count)!
        
        
        let originalData = sphereNode.geometry?.sources.first?.data
        originalVertexPositions = [Float](repeating: 0, count: verticesCount)
        for i in 0..<verticesCount {
            originalVertexPositions[i] = Float(originalData![i])
        }

        
        var translations = [Float]()
        
        print("Vertices count: ", verticesCount)
        
        /* Note: this is SceneKit Shader Modifier
         FOR MORE DETAILS, please read https://developer.apple.com/documentation/scenekit/scnprogram
         Video (a bit old): https://www.youtube.com/watch?v=rkkUfeDYiU8&ab_channel=ramacad
         For texture stuff, we can probably add a "fragment shader modifier" (for example: https://stackoverflow.com/questions/54562128/how-to-write-a-scenekit-shader-modifier-for-a-dissolve-in-effect)
         */
        
        let shader = """
            #pragma arguments
            float zTranslation;
            int verticesCount;
            float *vertexTranslations;
        

            #pragma transparent
            #pragma body
            float4x4 transform = float4x4(1);
        
            for (int i = 0; i < verticesCount; i++) {
                if (scn_vertexID == i) {
                    transform[3][2] = vertexTranslations[i];
                }
            }
            _geometry.position *= transform;
        """
        
        // send params to shader!!
        sphereNode.geometry?.firstMaterial?.shaderModifiers = [.geometry: shader]
        
        sphereNode.geometry?.firstMaterial?.setValue(verticesCount, forKey: "verticesCount")
        
        sphereNode.geometry?.firstMaterial?.setValue(0, forKey: "zTranslation")
    }
    
    // TODO: for smoother animation, especially with shape deformation, we might want to consider adding noise (e.g., Perlin, Simplex). Perhaps we could add Simplex noise to add some random, organic-looking distortion to the sphere geometry. By animating the noise over time, it creates a wavy, liquid-like effect...right now it's very jarring.
    // Nhan: I have added PerlinNoise file in this project that we can easily call (https://github.com/jdjack/Swift-Perlin-Noise) but haven't used it yet, feel free to play around with others like Simplex as well (github has lots of these implementations so we don't need to reinvent the wheel here)
    private func animate() {
        guard isAnimating else { return }
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 2.0
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        SCNTransaction.completionBlock = {
            self.animate()
        }
        zTranslation = zTranslation == 0.0 ? -1.0 : 0.0
        sphereNode.geometry?.firstMaterial?.setValue(zTranslation, forKey: "zTranslation")
        
        
        var translations = [Float]()

        for _ in 0..<verticesCount {
            let randomTranslation = Float.random(in: -1...1)
            translations.append(randomTranslation)
        }
        
        let vertexIndicesData = NSData(bytes: translations, length: verticesCount * MemoryLayout<Float>.stride)
        sphereNode.geometry?.firstMaterial?.setValue(verticesCount, forKey: "verticesCount")
        sphereNode.geometry?.firstMaterial?.setValue(vertexIndicesData, forKey: "vertexTranslations")
                
        SCNTransaction.commit()
    }
    
    private func stopAnimation() {
        isAnimating = false
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
                
        sphereNode.geometry?.firstMaterial?.setValue(originalVertexPositions , forKey: "vertexTranslations")
        SCNTransaction.commit()
    }

    private func startAnimation() {
        isAnimating = true
        animate()
    }

}

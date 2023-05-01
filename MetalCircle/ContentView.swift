//
//  ContentView.swift
//  MetalCircle
//
//  Created by Nhan Tran on 4/2/23.
//

import SwiftUI
import MetalKit

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(destination: AudioVisualizerView()) {
                    Text("Audio Visualizer")
                        .font(.title)
                        .padding()
                }
                
                NavigationLink(destination: SphereDeformable()) {
                    Text("Sphere Deformable")
                        .font(.title)
                        .padding()
                }
            }
            .navigationBarTitle("Select a View", displayMode: .inline)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().edgesIgnoringSafeArea(.all)
    }
}

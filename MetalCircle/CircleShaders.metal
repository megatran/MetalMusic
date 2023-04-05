//
//  Shaders.metal
//  MetalCircle
//
//  Created by Nhan Tran on 4/2/23.
//

#include <metal_stdlib>
#include <simd/simd.h>

#include "definitions.h"
using namespace metal;


/*
 We need a common language between Swift and Metal
 This struct/container can be read by both Swift (CPU side)
 and Metal (GPU side).
 */
struct VertexOut {
    vector_float4 position [[position]];
    vector_float4 color;
};

/**
 Vertex Shader
 Input: *vertexArray is our array of verticies (on Swift side)
 The attribute [[buffer(0)]] specifies the first and only buffer data to be passed in
 the constant attribute tells Metal to store the vertices in read-only memory space
 vertex_id uniquely identifies which vertex we're currently on. Also index for our vertexArray
 Output: VectorOut which holds the position and color vector
 */
 vertex VertexOut vertexShader(unsigned int vid [[vertex_id]],
                               const constant vector_float2 *vertexArray [[buffer(0)]],
                               const constant float *loudnessUniform [[buffer(1)]],
                               const constant float *lineArray [[buffer(2)]],
                               constant float &aspectRatio [[buffer(3)]]) {
     
     // index the loudnessUniform array at zero because there is only one element in it
     float circleScaler = loudnessUniform[0];
     
     VertexOut output;
     if (vid < 1081) {
         // circle
         vector_float2 currentVertex = vertexArray[vid]; //fetch the current vertex we're on using the vid to index into our buffer data which holds all of our vertex points that we passed in
         output.position = vector_float4(currentVertex.x*circleScaler, currentVertex.y*circleScaler, 0, 1); //populate the output position with the x and y values of our input vertex data
        output.color =  vector_float4(0,0,0,1);//set the color
        //output.color =  vector_float4(1,1,1,1);
     } else {
         // frequency line
         int circleId = vid-1081;
         vector_float2 circleVertex;

         if(circleId%3 == 0){
             //place line vertex off circle
             circleVertex = vertexArray[circleId];
             float lineScale = 1 + lineArray[(vid-1081)/3];
             output.position = vector_float4(circleVertex.x*circleScaler*lineScale, circleVertex.y*circleScaler*lineScale, 0, 1);
             output.color = vector_float4(0,0,1,1);
         } else {
             //place line vertex on circle
             circleVertex = vertexArray[circleId-1];
             output.position = vector_float4(circleVertex.x*circleScaler, circleVertex.y*circleScaler, 0, 1);
             output.color = vector_float4(1,0,0,1);
         }
     }
     output.position.y *= aspectRatio; // Apply the aspect ratio to the y-coordinate
     return output;
 }

/**
 Fragment Shader
 Input: interpoted
 [[stage_in]] atrribute tells Metal that the variable should be fed in the interpolated results of the rasterizer.
 */
fragment vector_float4 fragmentShader(VertexOut interpolated [[stage_in]]) {
    return interpolated.color;
}

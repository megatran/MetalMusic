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
                               constant float &aspectRatio [[buffer(1)]]) {
     vector_float2 current_vertex = vertexArray[vid];
     VertexOut output;

     output.position = vector_float4(current_vertex.x, current_vertex.y, 0, 1);
     output.position.y *= aspectRatio; // Apply the aspect ratio to the x-coordinate
     output.color = vector_float4(1,1,1,1);
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


//struct Fragment {
//    float4 position [[position]];
//    float4 color;
//};
//
//vertex Fragment vertexShader(const constant Vertex *vertexArray [[buffer(0)]],
//    unsigned int vid [[vertex_id]]) {
//    Vertex input = vertexArray[vid];
//    Fragment output;
//
//    output.position = float4(input.position.x, input.position.y, 0, 1);
//    output.color = input.color;
//    return output;
//}
//
//fragment float4 fragmentShader(Fragment interpolated [[stage_in]]) {
//    return interpolated.color;
//}



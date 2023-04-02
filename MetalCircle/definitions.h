//
//  definitions.h
//  MetalCircle
//
//  Created by Nhan Tran on 4/2/23.
//

#ifndef definitions_h
#define definitions_h


#endif /* definitions_h */

#include <simd/simd.h>

// This struct can be read by both Swift and shader
// Not using it for now. Maybe later
struct Vertex {
    vector_float2 position;
    vector_float4 color;
};

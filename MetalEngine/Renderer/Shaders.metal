//
//  Shaders.metal
//  MetalEngine
//
//  Created by Lachlan Russell on 12/11/21.
//

// File for Metal kernel and shader functions

#include <metal_stdlib>
#include <simd/simd.h>

// Including header shared between this Metal shader code and Swift/C code executing Metal API commands
#import "ShaderTypes.h"

using namespace metal;

typedef struct
{
    float3 position [[attribute(VertexAttributePosition)]];
    //    float2 texCoord [[attribute(VertexAttributeTexcoord)]];
} Vertex;

typedef struct
{
    float4 position [[position]];
    float2 texCoord;
    float4 color;
} ColorInOut;



vertex ColorInOut vertexShader(device Vertex *vertices [[buffer(0)]],
    uint vid [[vertex_id]],
    constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]])
{
    ColorInOut out;
    Vertex in       = vertices[vid];
    float4 position = float4(in.position, 1.0);
    out.position    = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;
    out.color       = float4(255, 255, 0, 1.0);
    return out;
}

fragment float4 fragmentShader(ColorInOut in [[stage_in]])
{
    return in.color;
}

// vertex ColorInOut vertexShader(Vertex in [[stage_in]],
//                                constant Uniforms & uniforms [[ buffer(BufferIndexUniforms) ]])
//{
//     ColorInOut out;
//
//     float4 position = float4(in.position, 1.0);
//     out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;
//     out.texCoord = in.texCoord;
//
//     return out;
// }
//
// fragment float4 fragmentShader(ColorInOut in [[stage_in]],
//                                constant Uniforms & uniforms [[ buffer(BufferIndexUniforms) ]],
//                                texture2d<half> colorMap     [[ texture(TextureIndexColor) ]])
//{
//     constexpr sampler colorSampler(mip_filter::linear,
//                                    mag_filter::linear,
//                                    min_filter::linear);
//
//     half4 colorSample   = colorMap.sample(colorSampler, in.texCoord.xy);
//
//     return float4(colorSample);
// }

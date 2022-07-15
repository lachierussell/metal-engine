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
    float3 normal [[attribute(VertexAttributeNormal)]];
} Vertex;

typedef struct
{
    float4 position [[position]];
    float3 color;
    float3 modelViewPosition;
    float3 normalInterp;
} ColorInOut;

vertex ColorInOut vertexShader(
    const device Vertex *vertices [[buffer(0)]],
    uint vid [[vertex_id]],
    constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]])
{
    ColorInOut out;
    Vertex in = vertices[vid];
    
    float4 modelViewVector = uniforms.modelViewMatrix * float4(in.position, 1.0);
    
    out.position          = uniforms.projectionMatrix * uniforms.modelViewMatrix * float4(in.position, 1.0);
    out.modelViewPosition = modelViewVector.xyz / modelViewVector.w;
    out.normalInterp      = uniforms.normalMatrix * in.normal;
    out.color             = float3(0.5, 0.5, 0.5);
    return out;
}

fragment float4 fragmentShader(
    ColorInOut in [[stage_in]],
    constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]])
{
    // Light attributes
    const float3 lightPosition = float3(0, 50, 0);
    const float3 lightColor    = float3(1.0, 1.0, 1.0);
    const float lightPower     = 10000.0;

    // Object attributes
    const float shininess      = 8;
    const float3 specularColor = float3(0.1, 0.1, 0.1);
    const float3 diffuseColor  = float3(0.5, 0.5, 0.5);
    const float3 ambientColor  = float3(0.1, 0.1, 0.1);

    float3 normal = normalize(in.normalInterp);  // Need to normalize interpolated normals
    float3 lightDirection = lightPosition - in.modelViewPosition;
    float lightDistance = length(lightDirection);
    lightDistance = pow(lightDistance, 2);
    lightDirection = normalize(lightDirection);
    
    float lamertian = max(dot(lightDirection, normal), 0.0);
    float specular = 0.0;
    
    if (lamertian > 0.0) {
        float3 viewDirection = normalize(-in.modelViewPosition);
        
        float3 halfway = normalize(lightDirection + viewDirection);
        float specularAngle = max(dot(halfway, normal), 0.0);
        
        specular = pow(specularAngle, shininess);
    }
    
    float3 colorLinear = ambientColor
                    + diffuseColor * lamertian * lightColor * lightPower / lightDistance
                    + specularColor * specular * lightColor * lightPower / lightDistance;
    
//    return float4(0.5, 0.5, 0.5, 1.0);
    return float4(colorLinear, 1.0);
}

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
    float4 modelViewPosition;
    float4 normal;
    float4 cameraDirection;
    float4 color;
} ColorInOut;

vertex ColorInOut vertexShader(
    const device Vertex *vertices [[buffer(0)]],
    uint vid [[vertex_id]],
    constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]])
{
    ColorInOut out;
    Vertex in = vertices[vid];
    
    float4 normal = uniforms.viewMatrix * uniforms.modelMatrix * float4(in.normal, 1.0);
    
    out.modelViewPosition = float4(in.position, 1.0) * uniforms.modelMatrix * uniforms.viewMatrix;
    out.position          = uniforms.projectionMatrix * out.modelViewPosition;
    out.normal            = normalize(normal);
    out.color = float4(0.1, 0.0, 0.1, 1.0);
    return out;
}

fragment float4 fragmentShader(
    ColorInOut in [[stage_in]],
    constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]])
{
    // Light attributes
    const float4 lightPosition  = float4(100, 50, 100, 1.0);
    const float4 lightColor     = float4(1.0, 1.0, 1.0, 1.0);
    const float lightPower      = 50;
    const float point = 1.0;
    const float tube = 1.0;
    const float ambient = 1.0;
    
    // Object attributes
    const float shininess = 30;
    const float4 specularProduct  = float4(1.0, 1.0, 1.0, 1.0);
    const float4 diffuseProduct   = float4(1.0, 1.0, 1.0, 1.0);
    const float4 ambientProduct   = float4(1.0, 1.0, 1.0, 1.0);
    
    float4 normal = normalize(in.normal);
    float4 view = normalize(-in.modelViewPosition);
    
    float4 lightVector = lightPosition - in.modelViewPosition;
    float lightDistance = length(lightVector);
    float attenuation = 1.0
        / ((point * pow(lightDistance, 2.0)) + (tube * lightDistance) + ambient);
    
    float4 light = normalize(lightVector);
    float4 halfway = normalize(light + view);
    
    float kd = max(dot(light, normal), 0.0);
    float4 diffuse = kd * diffuseProduct;
    
    float ks = pow(max(dot(normal, halfway), 0.0), shininess);
    float4 specular = ks * specularProduct;
    
//    if(dot(light, normal) > 0.0) {
//        specular = float4(0, 0, 0, 0);
//    }
    float4 outColor;
    
    outColor = float4(0.1, 0.1, 0.1, 1.0);
    
    float4 highlightFactor = lightPower * lightColor;
    
    float4 phong = attenuation * highlightFactor * (diffuse + specular);
    
    
//    outColor = (phong + ambientProduct) * in.color;

    return in.color;
}

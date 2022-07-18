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
    float4 color;
    float3 viewPosition;
    float3 globalPosition;
    float3 normal;
    float4 bypass;
} ColorInOut;


vertex ColorInOut vertexShader(
    const device Vertex *vertices [[buffer(0)]],
    uint vid [[vertex_id]],
    constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]])
{
    ColorInOut out;
    Vertex in = vertices[vid];

    float4 modelViewVector = uniforms.modelViewMatrix * float4(in.position, 1.0);
    float4 modelVector = uniforms.modelMatrix * float4(in.position, 1.0);
    float4 normalVector = uniforms.modelViewMatrix * float4(in.normal, 1.0);

    out.position        = uniforms.projectionMatrix * uniforms.modelViewMatrix * float4(in.position, 1.0);
    out.viewPosition    = modelViewVector.xyz / modelViewVector.w;
    out.globalPosition  = modelVector.xyz / modelVector.w;
    out.normal          = (uniforms.modelViewMatrix * float4(in.normal, 1.0)).xyz;
    out.color           = normalize(uniforms.modelViewMatrix * float4(in.position, 1.0));

    out.bypass = float4(out.normal, 1.0);
    
    return out;
}

fragment float4 fragmentShader(
    ColorInOut in [[stage_in]],
    constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]])
{
    // Light attributes
    
    const float4 light4Position = uniforms.viewMatrix * float4(50, 25, 0, 1.0);

    const float3 lightPosition = light4Position.xyz / light4Position.w;  // Global position
    const float3 lightColor    = float3(1.0, 1.0, 1.0);
    const float lightPower     = 100;

    // Object attributes
    const float shininess      = 30;
    const float3 specularColor = float3(0.5, 0.5, 0.5);
    const float3 diffuseColor  = float3(0.1, 0.1, 0.1);
    const float3 ambientColor  = float3(0.1, 0.1, 0.1);
    
    float3 normal         = normalize(in.normal); // Need to normalize interpolated normals
    float3 lightDirection = lightPosition - in.viewPosition;
    float lightDistance   = length(lightDirection);
    lightDistance         = pow(lightDistance, 1);
    lightDirection        = normalize(lightDirection);

    float lamertian = max(dot(lightDirection, normal), 0.0);
    float specular  = 0.0;

    if (lamertian > 0.0) {
        float3 viewDirection = normalize(-in.viewPosition);
        
        if (true) { // Phong
            float3 reflectionVec = reflect(-lightDirection, normal);
            float specularAngle = max(dot(reflectionVec, viewDirection), 0.0);
            specular = pow(specularAngle, shininess / 4.0);
            specular = 0;
        } else { // Blinn
            float3 halfway      = normalize(lightDirection + viewDirection);
            float specularAngle = max(dot(halfway, normal), 0.0);
            specular = pow(specularAngle, shininess);
        }
    }

    float3 colorLinear = ambientColor
        + diffuseColor * lamertian * lightColor * lightPower / lightDistance
        + specularColor * specular * lightColor * lightPower / lightDistance;


//    return in.bypass;
    return float4(colorLinear, 1.0);
}

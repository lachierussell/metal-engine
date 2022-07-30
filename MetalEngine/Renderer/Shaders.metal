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
    float3 viewPosition;
    float3 globalPosition;
    float3 modelPosition;
    float3 normal;
    float4 bypass;
} ColorInOut;

float3 surface(float height, float3 normal)
{
    float3 vertical = float3(0, 1, 0);
    float angle     = dot(normalize(normal), normalize(vertical));  // 0 if face is on it's edge

    float3 color = float3(1.0, 1.0, 1.0);

    if (height < 15) {
        if (height <= 0) {
            color = float3(0, 0.4, 0.8);  // Blue
        } else if (height < 0.2) {
            color = float3(0.89, 0.8, 0.6);  // Sand
        } else if (angle > 0.7) {
            color = float3(0.21, 0.45, 0.2);  // Green
        } else {
            color = float3(0.4, 0.2, 0.15);  // Brown
        }
    }
    return color;
}

vertex ColorInOut vertexShader(
    const device Vertex *vertices [[buffer(0)]],
    uint vid [[vertex_id]],
    constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]])
{
    ColorInOut out;
    Vertex in = vertices[vid];

    float4 modelViewPosition = uniforms.modelViewMatrix * float4(in.position, 1.0);
    float4 modelPosition     = uniforms.modelMatrix * float4(in.position, 1.0);
    float4 normalVector      = uniforms.modelViewMatrix * float4(in.normal, 0.0);

    out.position       = uniforms.projectionMatrix * uniforms.modelViewMatrix * float4(in.position, 1.0);
    out.viewPosition   = modelViewPosition.xyz / modelViewPosition.w;
    out.globalPosition = modelPosition.xyz / modelPosition.w;
    out.modelPosition  = in.position;
    out.normal         = normalize(normalVector.xyz);
    out.color          = surface(in.position.y, in.normal);

    out.bypass = float4(in.normal, 0.0);
    return out;
}

fragment float4 fragmentShader(
    ColorInOut in [[stage_in]],
    constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]])
{
    float3 inColor = surface(in.modelPosition.y, in.color);
    //    inColor = in.color;

    // Light attributes
    const float4 light4Position = uniforms.viewMatrix * float4(1000, 1000, 50, 1.0);

    const float3 lightPosition = light4Position.xyz / light4Position.w;  // Global position
    const float3 lightColor    = float3(1.0, 1.0, 1.0);
    const float lightPower     = 1;

    // Object attributes
    const float shininess      = 5;
    const float3 specularColor = 1.0 * inColor;
    const float3 diffuseColor  = 0.7 * inColor;
    const float3 ambientColor  = 0.7 * inColor;

    float3 normal         = normalize(in.normal);  // Need to normalize interpolated normals
    float3 lightDirection = lightPosition - in.viewPosition;
    float lightDistance   = length(lightDirection);
    lightDistance         = pow(lightDistance, 0);
    lightDirection        = normalize(lightDirection);

    float lamertian = saturate(dot(lightDirection, normal));
    float specular  = 0;

    if (lamertian > 0.0) {
        float3 viewDirection = normalize(-in.viewPosition);

        if (true) {  // Phong
            float3 reflectionVec = reflect(-lightDirection, normal);
            float specularAngle  = saturate(dot(reflectionVec, viewDirection));
            specular             = pow(specularAngle, shininess / 4.0);
        } else {  // Blinn
            float3 halfway      = normalize(lightDirection + viewDirection);
            float specularAngle = max(dot(halfway, normal), 0.0);
            specular            = pow(specularAngle, shininess);
        }
    }

    float3 colorLinear = ambientColor
        + diffuseColor * lamertian * lightColor * lightPower / lightDistance
        + specularColor * specular * lightColor * lightPower / lightDistance;

    // apply gamma correction (assume ambientColor, diffuseColor and specColor
    // have been linearized, i.e. have no gamma correction in them)
    float screenGamma          = 1.8;
    float3 colorGammaCorrected = pow(colorLinear, float3(1.0 / screenGamma));
    // use the gamma corrected color in the fragment

    //    return normalize(in.bypass);
    return float4(colorGammaCorrected, 1.0);
}

//
//  ShaderTypes.h
//  MetalEngine
//
//  Created by Lachlan Russell on 12/11/21.
//

//
//  Header containing types and enum constants shared between Metal shaders and Swift/ObjC source
//
#ifndef ShaderTypes_h
#define ShaderTypes_h

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) \
    enum _name : _type _name; \
    enum _name : _type
#define NSInteger metal::int32_t
#else
#import <Foundation/Foundation.h>
#endif

#include <simd/simd.h>

typedef NS_ENUM(NSInteger, BufferIndex) {
    BufferIndexMeshPositions = 0,
    BufferIndexMeshNormals   = 1,
    BufferIndexUniforms      = 2
};

typedef NS_ENUM(NSInteger, VertexAttribute) {
    VertexAttributePosition = 0,
    VertexAttributeNormal   = 1,
};

typedef NS_ENUM(NSInteger, TextureIndex) {
    TextureIndexColor = 0,
};

typedef struct
{
    matrix_float4x4 projectionMatrix;
    matrix_float3x3 normalMatrix;
    matrix_float4x4 modelViewMatrix;
    matrix_float4x4 modelMatrix;
    matrix_float4x4 viewMatrix;
} Uniforms;

#endif /* ShaderTypes_h */

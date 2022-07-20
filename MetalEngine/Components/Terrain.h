//
//  Terrain.h
//  MetalEngine
//
//  Created by Lachlan Russell on 13/7/2022.
//

#import <Foundation/Foundation.h>
#import <GameplayKit/GameplayKit.h>
#import <MetalKit/MetalKit.h>
#import <ModelIO/ModelIO.h>
#import <simd/simd.h>

@interface Terrain : NSObject

- (instancetype)initWithDevice:(id<MTLDevice>)device width:(int)width length:(int)length;
- (instancetype)initFalloffWithDevice:(id<MTLDevice>)device width:(int)width length:(int)length;
- (void)createBlankMesh;
- (void)tesalate;
- (void)growMesh;
- (void)updateBuffer;
- (id<MTLBuffer>)getMesh;
- (int)getVerticies;

@end

typedef struct {
    simd_float3 position;
    simd_float3 normal;
} VERTEX;

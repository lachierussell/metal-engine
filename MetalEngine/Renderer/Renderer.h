//
//  Renderer.h
//  MetalEngine
//
//  Created by Lachlan Russell on 12/11/21.
//

#import <GameplayKit/GameplayKit.h>
#import <MetalKit/MetalKit.h>
#import <ModelIO/ModelIO.h>
#import <simd/simd.h>
#import <Foundation/Foundation.h>

// Include header shared between C code here, which executes Metal API commands, and .metal files
#import "../Components/Terrain.h"
#import "ShaderTypes.h"

// Our platform independent renderer class.   Implements the MTKViewDelegate protocol which
//   allows it to accept per-frame update and drawable resize callbacks.
@interface Renderer : NSObject <MTKViewDelegate>

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view;

@end


/*
 
 
 lightDirection    float3    [ 0.1956455112, 0.2590906024, 0.9458303452 ] // 1
 lightDirection    float3    [ 34.0812110901, 45.1332702637, 164.7624969482 ] // 2
 
 lightDistance    float    174.1987915039
 lightDistance    float    174.1987915039
 */

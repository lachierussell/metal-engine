//
//  PCDRCamera.h
//  MetalEngine
//
//  Created by Lachlan Russell on 13/7/2022.
//

#ifndef PCDRCamera_h
#define PCDRCamera_h

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import <GameplayKit/GameplayKit.h>
#import <MetalKit/MetalKit.h>
#import <ModelIO/ModelIO.h>
#import <simd/simd.h>

// List the keys in use within this sample
// The enum value is the NSEvent key code
// NS_OPTIONS(uint8_t, Controls) {
//    // Keycodes that control translation
//    controlsForward     = 0x0d, // W key
//    controlsBackward    = 0x01, // S key
//    controlsStrafeUp    = 0x31, // Spacebar
//    controlsStrafeDown  = 0x08, // C key
//    controlsStrafeLeft  = 0x00, // A key
//    controlsStrafeRight = 0x02, // D key
//
//    // Keycodes that control rotation
//    controlsRollLeft  = 0x0c, // Q key
//    controlsRollRight = 0x0e, // E key
//    controlsTurnLeft  = 0x7b, // Left arrow
//    controlsTurnRight = 0x7c, // Right arrow
//    controlsTurnUp    = 0x7e, // Up arrow
//    controlsTurnDown  = 0x7d, // Down arrow
//
//    // The brush size
//    controlsIncBrush = 0x1E, // Right bracket
//    controlsDecBrush = 0x21, // Left bracket
//
//    // Additional virtual keys
//    controlsFast = 0x80,
//    controlsSlow = 0x81
//};

@interface PCDRCamera : NSResponder {
@public
    matrix_float4x4 viewMatrix;
}
- (nonnull instancetype)initWithPosition:(simd_float4)position;
- (void)keyDown:(nullable NSEvent *)event;
- (void)updateWithTimeDelta:(float)timeDelta;
- (simd_float4)getPosition;
- (simd_float4x4)getViewMatrix;

matrix_float4x4 matrix4x4_translation(float tx, float ty, float tz);
matrix_float4x4 matrix4x4_rotation(float radians, vector_float3 axis);
matrix_float4x4 matrix_perspective_right_hand(float fovyRadians, float aspect, float nearZ, float farZ);

@end

#endif /* PCDRCamera_h */

//
//  Camera.m
//  MetalEngine
//
//  Created by Lachlan Russell on 13/7/2022.
//

#import "PCDRCamera.h"


@implementation PCDRCamera {
    simd_float4 _inversePosition;
    simd_float4x4 _viewMatrix;
}

- (nonnull instancetype)initWithPosition: (simd_float4)position
{
    self = [super init];
    if (self) {
        simd_float4x4 viewMatrix = matrix_identity_float4x4;
        _inversePosition = matrix_multiply(position, viewMatrix);
        _viewMatrix = matrix4x4_translation(-50, -30, -100.0);
        [NSEvent addLocalMonitorForEventsMatchingMask: NSEventMaskKeyDown
                                              handler: ^NSEvent*(NSEvent* event){
            [self keyDown:event];
            return nil;
        }];
    }
    return self;
}

- (simd_float4)getPosition
{
    return _inversePosition;
}

- (simd_float4x4)getViewMatrix
{
    return _viewMatrix;
}

- (void)updateWithTimeDelta: (float)timeDelta
{
    
}

- (void)keyDown: (nullable NSEvent*)event
{
    simd_float4x4 rotation;
    simd_float4x4 translation;
    float rotateSpeed = 0.05;
    float translateSpeed = 5;
    
    switch (event.keyCode) {
        case 125:
//            NSLog(@"Rotate down");
            rotation = matrix4x4_rotation(rotateSpeed, (simd_float3){1, 0, 0});
            _viewMatrix = matrix_multiply(rotation, _viewMatrix);
            break;
        case 126:
//            NSLog(@"Rotate up");
            rotation = matrix4x4_rotation(-rotateSpeed, (simd_float3){1, 0, 0});
            _viewMatrix = matrix_multiply(rotation, _viewMatrix);
            break;
        case 123:
//            NSLog(@"Rotate left");
            rotation = matrix4x4_rotation(-rotateSpeed, (simd_float3){0, 1, 0});
            _viewMatrix = matrix_multiply(rotation, _viewMatrix);
            break;
        case 124:
//            NSLog(@"Rotate right");
            rotation = matrix4x4_rotation(rotateSpeed, (simd_float3){0, 1, 0});
            _viewMatrix = matrix_multiply(rotation, _viewMatrix);
            break;
        case 13:
//            NSLog(@"Move forward");
            translation = matrix4x4_translation(0, 0, translateSpeed);
            _viewMatrix = matrix_multiply(translation, _viewMatrix);
            break;
        case 1:
//            NSLog(@"Move backward");
            translation = matrix4x4_translation(0, 0, -translateSpeed);
            _viewMatrix = matrix_multiply(translation, _viewMatrix);
            break;
        case 0:
//            NSLog(@"Move left");
            translation = matrix4x4_translation(translateSpeed, 0, 0);
            _viewMatrix = matrix_multiply(translation, _viewMatrix);
            break;
        case 2:
//            NSLog(@"Move right");
            translation = matrix4x4_translation(-translateSpeed, 0, 0);
            _viewMatrix = matrix_multiply(translation, _viewMatrix);
            break;
        default:
            NSLog(@"%@", event.description);
    }
}

matrix_float4x4 matrix4x4_translation(float tx, float ty, float tz)
{
    return (matrix_float4x4) {
        {{ 1, 0, 0, 0 },
         { 0, 1, 0, 0 },
         { 0, 0, 1, 0 },
         { tx, ty, tz, 1 }}
    };
}

matrix_float4x4 matrix4x4_rotation(float radians, vector_float3 axis)
{
    axis     = vector_normalize(axis);
    float ct = cosf(radians);
    float st = sinf(radians);
    float ci = 1 - ct;
    float x = axis.x, y = axis.y, z = axis.z;

    return (matrix_float4x4) {
        {{ ct + x * x * ci, y * x * ci + z * st, z * x * ci - y * st, 0 },
         { x * y * ci - z * st, ct + y * y * ci, z * y * ci + x * st, 0 },
         { x * z * ci + y * st, y * z * ci - x * st, ct + z * z * ci, 0 },
         { 0, 0, 0, 1 }}
    };
}

matrix_float4x4 matrix_perspective_right_hand(float fovyRadians, float aspect, float nearZ, float farZ)
{
    float ys = 1 / tanf(fovyRadians * 0.5);
    float xs = ys / aspect;
    float zs = farZ / (nearZ - farZ);

    return (matrix_float4x4) {
        {{ xs, 0, 0, 0 },
         { 0, ys, 0, 0 },
         { 0, 0, zs, -1 },
         { 0, 0, nearZ * zs, 0 }}
    };
}

@end

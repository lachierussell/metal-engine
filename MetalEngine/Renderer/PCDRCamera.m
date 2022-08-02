//
//  Camera.m
//  MetalEngine
//
//  Created by Lachlan Russell on 13/7/2022.
//

#import "PCDRCamera.h"

@implementation PCDRCamera {
    float _verticalAngle;
    float _horizontalAngle;
    simd_float4x4 _translation;
}

- (nonnull instancetype)initWithPosition:(simd_float4)position
{
    self = [super init];
    if (self) {
        _translation = matrix4x4_translation(position.x, position.y, position.z);
        [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown
                                              handler:^NSEvent *(NSEvent *event) {
                                                  [self keyDown:event];
                                                  return nil;
                                              }];
    }
    return self;
}

- (simd_float4x4)getViewMatrix
{
    simd_float4x4 viewMatrix = _translation;

    simd_float4x4 horizontal = matrix4x4_rotation(_horizontalAngle, (simd_float3) { 0, 1, 0 });
    simd_float4x4 vertical   = matrix4x4_rotation(_verticalAngle, (simd_float3) { 1, 0, 0 });

    viewMatrix = matrix_multiply(horizontal, viewMatrix);
    viewMatrix = matrix_multiply(vertical, viewMatrix);

    return viewMatrix;
}

- (simd_float4x4)getHorizontalRotation
{
    return matrix4x4_rotation(_horizontalAngle, (simd_float3) { 0, 1, 0 });
}

- (void)updateWithTimeDelta:(float)timeDelta
{
}

- (void)keyDown:(nullable NSEvent *)event
{
    simd_float4x4 translation;
    float rotateSpeed    = 0.05;
    float translateSpeed = 5 / 3;

    switch (event.keyCode) {
    case 125:
        // NSLog(@"Rotate down");
        _verticalAngle += rotateSpeed;
        break;
    case 126:
        // NSLog(@"Rotate up");
        _verticalAngle -= rotateSpeed;
        break;
    case 123:
        // NSLog(@"Rotate left");
        _horizontalAngle -= rotateSpeed;
        break;
    case 124:
        // NSLog(@"Rotate right");
        _horizontalAngle += rotateSpeed;
        break;
    case 13:
        // NSLog(@"Move forward");
        translation  = matrix4x4_translation(0, 0, translateSpeed);
        translation  = rotateTranslation([self getHorizontalRotation], translation);
        _translation = matrix_multiply(translation, _translation);
        break;
    case 1:
        // NSLog(@"Move backward");
        translation  = matrix4x4_translation(0, 0, -translateSpeed);
        translation  = rotateTranslation([self getHorizontalRotation], translation);
        _translation = matrix_multiply(translation, _translation);
        break;
    case 0:
        // NSLog(@"Move left");
        translation  = matrix4x4_translation(translateSpeed, 0, 0);
        translation  = rotateTranslation([self getHorizontalRotation], translation);
        _translation = matrix_multiply(translation, _translation);
        break;
    case 2:
        // NSLog(@"Move right");
        translation  = matrix4x4_translation(-translateSpeed, 0, 0);
        translation  = rotateTranslation([self getHorizontalRotation], translation);
        _translation = matrix_multiply(translation, _translation);
        break;
    case 12:
        // NSLog(@"Move down");
        translation = matrix4x4_translation(0, translateSpeed / 4, 0);
        //        translation  = rotateTranslation([self getHorizontalRotation], translation);
        _translation = matrix_multiply(translation, _translation);
        break;
    case 14:
        // NSLog(@"Move up");
        translation = matrix4x4_translation(0, -translateSpeed / 4, 0);
        //        translation  = rotateTranslation([self getHorizontalRotation], translation);
        _translation = matrix_multiply(translation, _translation);
        break;
    default:
        NSLog(@"%@", event.description);
    }
}

simd_float4x4 rotateTranslation(simd_float4x4 rotation, simd_float4x4 translation)
{
    simd_float4x4 rotated = matrix_multiply(translation, rotation);
    return matrix_multiply(matrix_invert(rotation), rotated);
}

void matrix4x4_print(simd_float4x4 rotation)
{
    NSLog(@"Matrix 4x4:");
    NSLog(@"%f %f %f %f", rotation.columns[0].x, rotation.columns[1].x, rotation.columns[2].x, rotation.columns[3].x);
    NSLog(@"%f %f %f %f", rotation.columns[0].y, rotation.columns[1].y, rotation.columns[2].y, rotation.columns[3].y);
    NSLog(@"%f %f %f %f", rotation.columns[0].z, rotation.columns[1].z, rotation.columns[2].z, rotation.columns[3].z);
    NSLog(@"%f %f %f %f", rotation.columns[0].w, rotation.columns[1].w, rotation.columns[2].w, rotation.columns[3].w);
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

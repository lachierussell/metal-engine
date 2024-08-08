//
//  Terrain.m
//  MetalEngine
//
//  Created by Lachlan Russell on 13/7/2022.
//

#import "Terrain.h"
#import <float.h>
#import <UniformTypeIdentifiers/UTType.h>

@implementation Terrain : NSObject {
    simd_float3 *_vertices;
    VERTEX *_triangles;
    int _width;
    int _length;
    id<MTLBuffer> _mesh;
    id<MTLDevice> _device;
    int _iteration;
    float _lod;

    GKNoise *_noise;
    GKNoiseMap *_noiseMap;
    float *_falloffMap;
}

- (instancetype)initWithDevice:(id<MTLDevice>)device width:(int)width length:(int)length
{
    self = [super init];
    if (self) {
        [self initHelperWithDevice:device width:width length:length];
        [self growMesh];
    }
    return self;
}

- (instancetype)initFalloffWithDevice:(id<MTLDevice>)device width:(int)width length:(int)length
{
    self = [super init];
    if (self) {
        [self initHelperWithDevice:device
                             width:width
                            length:length];
        _falloffMap = [self generateFalloffMapWithWidth:width
                                                 length:length];
        [self growMesh];
    }
    return self;
}

- (void)initHelperWithDevice:(id<MTLDevice>)device width:(int)width length:(int)length
{
    _iteration = 0;
    _width     = width;
    _length    = length;
    _device    = device;
    _vertices  = calloc((width + 1) * (length + 1), sizeof(simd_float3));
    _triangles = calloc((width + 1) * (length + 1) * 6, sizeof(VERTEX));
    _lod       = 10;

    [self createBlankMesh];
    [self tesalate];

    _mesh = [_device newBufferWithBytes:_triangles
                                 length:(_width + 1) * (_length + 1) * 6 * sizeof(VERTEX)
                                options:MTLResourceOptionCPUCacheModeDefault];

    GKPerlinNoiseSource *perlinNoise = [[GKPerlinNoiseSource alloc] initWithFrequency:0.05
                                                                          octaveCount:4
                                                                          persistence:0.4
                                                                           lacunarity:2
                                                                                 seed:2];
    
    assert(perlinNoise != NULL);
    _noise = [[GKNoise alloc] initWithNoiseSource:perlinNoise];
    _noiseMap = [[GKNoiseMap alloc] initWithNoise:_noise
                                             size:simd_make_double2(8, 8)
                                           origin:simd_make_double2(0, 0)
                                      sampleCount:simd_make_int2(_width, _length)
                                         seamless:false];

}

- (void)saveNoiseMap
{
    
    SKTexture *texture = [SKTexture textureWithNoiseMap:_noiseMap];
    CGImageRef image = [texture CGImage];
    NSURL *url = [NSURL URLWithString:@"file:///Users/lachlan/Downloads/test2.png"];

    float compression = 1.0; // Lossless compression if available.
    int orientation = 4; // Origin is at bottom, left.
    CFStringRef myKeys[3];
    CFTypeRef   myValues[3];
    CFDictionaryRef myOptions = NULL;
    myKeys[0] = kCGImagePropertyOrientation;
    myValues[0] = CFNumberCreate(NULL, kCFNumberIntType, &orientation);
    myKeys[1] = kCGImagePropertyHasAlpha;
    myValues[1] = kCFBooleanTrue;
    myKeys[2] = kCGImageDestinationLossyCompressionQuality;
    myValues[2] = CFNumberCreate(NULL, kCFNumberFloatType, &compression);
    myOptions = CFDictionaryCreate( NULL, (const void **)myKeys, (const void **)myValues, 3,
                          &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    // Release the CFNumber and CFDictionary objects when you no longer need them.

    
    CGImageDestinationRef dest = CGImageDestinationCreateWithURL((CFURLRef)url, kUTTypePNG, 1, nil);
    
    CGImageDestinationAddImage(dest, image, myOptions);
    printf(CGImageDestinationFinalize(dest) ? "True\n": "False\n");
    CFRelease(dest);
}

- (void)createBlankMesh
{
    // Create Verticies
    for (int i = 0, l = 0; l <= _length; l++) {
        for (int w = 0; w <= _width; w++, i++) {
            _vertices[i] = simd_make_float3((float)w / _lod, 0, (float)l / _lod);
        }
    }
}

- (void)tesalate
{
    // Create Triangles
    for (int ti = 0, vi = 0, l = 0; l < _length; l++, vi++) {
        for (int w = 0; w < _width; w++, ti += 6, vi++) {
            _triangles[ti] = (VERTEX) {
                .position = _vertices[vi],
                .normal   = [self calculateNormalAt:vi]
            };
            _triangles[ti + 1] = (VERTEX) {
                .position = _vertices[vi + _width + 1],
                .normal   = [self calculateNormalAt:vi + _width + 1]
            };
            _triangles[ti + 2] = (VERTEX) {
                .position = _vertices[vi + 1],
                .normal   = [self calculateNormalAt:vi + 1]
            };
            _triangles[ti + 3] = (VERTEX) {
                .position = _vertices[vi + 1],
                .normal   = [self calculateNormalAt:vi + 1]
            };
            _triangles[ti + 4] = (VERTEX) {
                .position = _vertices[vi + _width + 1],
                .normal   = [self calculateNormalAt:vi + _width + 1]
            };
            _triangles[ti + 5] = (VERTEX) {
                .position = _vertices[vi + _width + 2],
                .normal   = [self calculateNormalAt:vi + _width + 2]
            };
        }
    }
}

- (float *)generateFalloffMapWithWidth:(float)width length:(float)length
{
    float *falloffMap = calloc((width + 1) * (length + 1), sizeof(float));

    for (int i = 0, l = 0; l <= length; l++) {
        for (int w = 0; w <= width; w++, i++) {
            float x = fabs(2 * l / (float)_length - 1);
            float y = fabs(2 * w / (float)_width - 1);

            float value = fmax(x, y);

            falloffMap[i] = fmin(fmax([Terrain evaluateFalloff:value], 0), 1);
        }
    }
    return falloffMap;
}

+ (float)evaluateFalloff:(float)value
{
    float a = 3;
    float b = 2.2;

    return pow(value, a) / (pow(value, a) + pow(b - b * value, a));
}

- (void)growMesh
{
    [self createBlankMesh];
    [_noise moveBy:(simd_double3){1, 0, 1}];
    _noiseMap = [GKNoiseMap noiseMapWithNoise:_noise
                                         size:simd_make_double2(_width + _iteration, _length + _iteration)
                                       origin:(simd_double2){0, 0}
                                  sampleCount:simd_make_int2(_width, _length)
                                     seamless:false];

    
    // Move verticies
    for (int i = 0, l = 0; l <= _length; l++) {
        for (int w = 0; w <= _width; w++, i++) {
            float noiseAtPosition = fmax([_noiseMap valueAtPosition:simd_make_int2(w, l)], 0);  // Between -1 and 1
            if (_falloffMap != NULL) {
                noiseAtPosition = fmax(fmin(noiseAtPosition - _falloffMap[i], 1), 0);
            }
            noiseAtPosition *= 10;
            _vertices[i].y = noiseAtPosition / _lod;
        }
    }

    _iteration++;

    [self tesalate];
    [self updateBuffer];
    [self saveNoiseMap];
}

- (simd_float3)calculateNormalAt:(int)vertex
{
    simd_float3 normal = simd_make_float3(0, 0, 0);

    int neighbours  = 6;
    int w           = _width;
    int index[6][3] = {
        {vertex - (w + 1), vertex, vertex - 1      },
        { vertex - w,      vertex, vertex - (w + 1)},
        { vertex + 1,      vertex, vertex - w      },
        { vertex + w + 1,  vertex, vertex + 1      },
        { vertex + w,      vertex, vertex + w + 1  },
        { vertex - 1,      vertex, vertex + w      }
    };

    int numVertex = (_width + 1) * (_length + 1);

    for (int i = 5; i < neighbours; i++) {
        simd_float3 extremity = simd_make_float3(0, 0, 0);
        if (index[i][0] > 0 && index[i][0] < numVertex
            && index[i][1] > 0 && index[i][1] < numVertex
            && index[i][2] > 0 && index[i][2] < numVertex) {
            simd_float3 pointA = _vertices[index[i][0]];
            simd_float3 pointB = _vertices[index[i][1]];
            simd_float3 pointC = _vertices[index[i][2]];

            extremity = [self surfaceNormalFromVectorsA:pointA B:pointB C:pointC];
            if (!simd_equal(extremity, simd_make_float3(0.0, 1.0, 0.0))) {
                //                NSLog(@"Vertex: %d Normal: %f %f %f", i, extremity.x, extremity.y, extremity.z);
                if (extremity.y == -300) {
                    extremity.y = 0;
                }
            }
            //            if (simd_dot(simd_make_float3(0, -1, 0), extremity) < 0) {
            //                NSLog(@"Vertex: %d Normal: %f %f %f", i, extremity.x, extremity.y, extremity.z);
            //            }
            //            extremity = simd_clamp(extremity, simd_make_float3(0, 0, 0), simd_make_float3(1, 1, 1));
        }
        normal += simd_normalize(extremity);
    }

    if (normal.y < 0) {
        //        NSLog(@"Normal less than 0");
    }
    return simd_clamp(simd_normalize(normal), 0, 1);
}

//- (void)calculateNormals
//{
//    int triangleCount = [self getVerticies] / 3;
//    //    simd_float3* vertexNormals = calloc(triangleCount, sizeof(simd_float3));
//
//    for (int i = 0; i < triangleCount; i++) {
//        int triangleIndex = i * 3;
//        _triangles[triangleIndex].normal     = normal;
//        _triangles[triangleIndex + 1].normal = normal;
//        _triangles[triangleIndex + 2].normal = normal;
//    }
//}

- (simd_float3)surfaceNormalFromTriangle:(int)triangleIndex
{
    simd_float3 vertexIndexA = _triangles[triangleIndex].position;
    simd_float3 vertexIndexB = _triangles[triangleIndex + 1].position;
    simd_float3 vertexIndexC = _triangles[triangleIndex + 2].position;

    return [self surfaceNormalFromVectorsA:vertexIndexA
                                         B:vertexIndexB
                                         C:vertexIndexC];
}

- (simd_float3)surfaceNormalFromVectorsA:(simd_float3)pointA B:(simd_float3)pointB C:(simd_float3)pointC
{
    simd_float3 sideAB       = pointB - pointA;
    simd_float3 sideBC       = pointB - pointC;
    simd_float3 crossProduct = simd_cross(sideAB, sideBC);

    return crossProduct;
}

- (id<MTLBuffer>)getMesh
{
    return _mesh;
}

- (int)getVerticies
{
    return (_width + 1) * (_length + 1) * 6;
}

- (void)updateBuffer
{
    memcpy([_mesh contents], _triangles, [self getVerticies] * sizeof(VERTEX));
}

@end

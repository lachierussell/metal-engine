//
//  Terrain.m
//  MetalEngine
//
//  Created by Lachlan Russell on 13/7/2022.
//

#import "Terrain.h"
#import <float.h>

@implementation Terrain : NSObject {
    simd_float3 *_vertices;
    VERTEX *_triangles;
    int _width;
    int _length;
    id<MTLBuffer> _mesh;
    id<MTLDevice> _device;
    int _iteration;

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
    _vertices = calloc((width + 1) * (length + 1), sizeof(simd_float3));
    _triangles = calloc(width * length * 6, sizeof(VERTEX));

    [self createBlankMesh];
    [self tesalate];

    _mesh = [_device newBufferWithBytes:_triangles
                                 length:_width * _length * 6 * sizeof(VERTEX)
                                options:MTLResourceOptionCPUCacheModeDefault];

    GKPerlinNoiseSource *perlinNoise = [[GKPerlinNoiseSource alloc] initWithFrequency:0.04
                                                                          octaveCount:5
                                                                          persistence:0.4
                                                                           lacunarity:1.9
                                                                                 seed:2];

    _noiseMap = [[GKNoiseMap alloc] initWithNoise:_noise
                                             size:simd_make_double2(_width, _length)
                                           origin:simd_make_double2(0, 0)
                                      sampleCount:simd_make_int2(_width, _length)
                                         seamless:true];

    assert(perlinNoise != NULL);
    _noise = [[GKNoise alloc] initWithNoiseSource:perlinNoise];
}

- (void)createBlankMesh
{
    // Create Verticies
    for (int i = 0, l = 0; l <= _length; l++) {
        for (int w = 0; w <= _width; w++, i++) {
            _vertices[i] = simd_make_float3(w, 0, l);
        }
    }
}

- (void)tesalate
{
    // Create Triangles
    for (int ti = 0, vi = 0, l = 0; l < _length; l++, vi++) {
        for (int w = 0; w < _width; w++, ti += 6, vi++) {
        
            _triangles[ti]    =
                (VERTEX){
                    .position = _vertices[vi],
                    .normal = [self calculateNormalAt:vi]
                };
            _triangles[ti + 1] = _triangles[ti + 4] =
                (VERTEX){
                    .position = _vertices[vi + _width + 1],
                    .normal = [self calculateNormalAt:vi + _width + 1]
                };
            _triangles[ti + 2] = _triangles[ti + 3] =
                (VERTEX){
                    .position = _vertices[vi + 1],
                    .normal = [self calculateNormalAt:vi + + 1]
                };
            _triangles[ti + 5] =
                (VERTEX){
                    .position = _vertices[vi + _width + 2],
                    .normal = [self calculateNormalAt:vi + _width + 2]
                };
        }
    }
}

- (float *)generateFalloffMapWithWidth:(float)width length:(float)length
{
    float *falloffMap = calloc(width * length, sizeof(float));

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
    _noiseMap = [GKNoiseMap noiseMapWithNoise:_noise
                                         size:simd_make_double2(_width + _iteration, _length + _iteration)
                                       origin:simd_make_double2(_iteration, _iteration)
                                  sampleCount:simd_make_int2(_width, _length)
                                     seamless:true];

    // Move verticies
    for (int i = 0, l = 0; l <= _length; l++) {
        for (int w = 0; w <= _width; w++, i++) {
            float noiseAtPosition = fmax([_noiseMap valueAtPosition:simd_make_int2(w, l)], 0); // Between -1 and 1
            if (_falloffMap != NULL) {
                noiseAtPosition = fmax(fmin(noiseAtPosition - _falloffMap[i], 1), 0);
            }
            noiseAtPosition *= 20;
            _vertices[i] = (simd_float3) { w, noiseAtPosition, l };
        }
    }

    _iteration++;

    [self tesalate];
    [self updateBuffer];
}

- (simd_float3)calculateNormalAt:(int)vertex
{
    simd_float3 center       = _vertices[vertex];
    simd_float3 normal = simd_make_float3(0, 0, 0);
    
    int neighbours = 6;
    
    int indexA[6] = {
        vertex - 1,
        vertex - (_width + 1),
        vertex - _width,
        vertex + 1,
        vertex + (_width + 1),
        vertex + _width
    };
    int indexB[6] = {
        vertex - (_width + 1),
        vertex - _width,
        vertex + 1,
        vertex + (_width + 1),
        vertex + _width,
        vertex - 1,
    };
    
    int numVertex = (_width + 1) * (_length + 1);
    
    for (int i = 0; i < neighbours; i++) {
        simd_float3 extremity = simd_make_float3(0, 0, 0);
        if (indexA[i] > 0 && indexA[i] < numVertex && indexB[i] > 0 && indexB[i] < numVertex) {
            simd_float3 pointA = _vertices[indexA[i]];
            simd_float3 pointC = _vertices[indexB[i]];
            
            extremity = [self surfaceNormalFromVectorsA:pointA B:center C:pointC];
//            NSLog(@"Vertex: %d Normal: %f %f %f", i, extremity.x, extremity.y, extremity.z);
        }
        if (extremity.x == NAN) {
            NSLog(@"%f", extremity.x);
        }
        normal += extremity;
    }
    
    return normal;
}

- (void)calculateNormals
{
    int triangleCount = [self getVerticies] / 3;
    //    simd_float3* vertexNormals = calloc(triangleCount, sizeof(simd_float3));

    for (int i = 0; i < triangleCount; i++) {
        int triangleIndex = i * 3;

        simd_float3 *normals = calloc(sizeof(simd_float3), 6);

        _triangles[triangleIndex].normal     = normal;
        _triangles[triangleIndex + 1].normal = normal;
        _triangles[triangleIndex + 2].normal = normal;
    }
}

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
    simd_float3 sideAB = pointB - pointA;
    simd_float3 sideAC = pointC - pointA;
    return simd_normalize(simd_cross(sideAB, sideAC));
}

- (id<MTLBuffer>)getMesh
{
    return _mesh;
}

- (int)getVerticies
{
    return _width * _length * 6;
}

- (void)updateBuffer
{
    memcpy([_mesh contents], _triangles, [self getVerticies] * sizeof(VERTEX));
}

@end

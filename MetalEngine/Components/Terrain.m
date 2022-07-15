//
//  Terrain.m
//  MetalEngine
//
//  Created by Lachlan Russell on 13/7/2022.
//

#import "Terrain.h"

@implementation Terrain : NSObject {
    simd_float3 *_verticies;
    VERTEX *_triangles;
    int _width;
    int _length;
    id<MTLBuffer> _mesh;
    id<MTLDevice> _device;
    int _iteration;

    GKNoise *_noise;
    GKNoiseMap *_noiseMap;
}

- (instancetype)initWithDevice:(id<MTLDevice>)device width:(int)width length:(int)length
{
    self = [super init];
    if (self) {
        _iteration = 0;
        _width     = width;
        _length    = length;
        _device    = device;
        _verticies = calloc((width + 1) * (length + 1), sizeof(simd_float3));
        _triangles = calloc(width * length * 6, sizeof(VERTEX));

        [self createBlankMesh];
        [self tesalate];

        _mesh = [_device newBufferWithBytes:_triangles
                                     length:_width * _length * 6 * sizeof(VERTEX)
                                    options:MTLResourceOptionCPUCacheModeDefault];

        GKPerlinNoiseSource *perlinNoise = [[GKPerlinNoiseSource alloc] initWithFrequency:0.01
                                                                              octaveCount:8
                                                                              persistence:0.5
                                                                               lacunarity:1.2
                                                                                     seed:5];

        _noiseMap = [[GKNoiseMap alloc] initWithNoise:_noise
                                                 size:simd_make_double2(_width, _length)
                                               origin:simd_make_double2(0, 0)
                                          sampleCount:simd_make_int2(_width, _length)
                                             seamless:true];

        assert(perlinNoise != NULL);
        _noise = [[GKNoise alloc] initWithNoiseSource:perlinNoise];
        [self evolveMesh];
    }
    return self;
}

- (void)createBlankMesh
{
    // Create Verticies
    for (int i = 0, l = 0; l <= _length; l++) {
        for (int w = 0; w <= _width; w++, i++) {
            _verticies[i] = simd_make_float3(w, 0, l);
        }
    }
}

- (void)tesalate
{
    // Create Triangles
    for (int ti = 0, vi = 0, l = 0; l < _length; l++, vi++) {
        for (int w = 0; w < _width; w++, ti += 6, vi++) {
            _triangles[ti].position     = _verticies[vi];
            _triangles[ti + 1].position = _verticies[vi + _width + 1];
            _triangles[ti + 2].position = _verticies[vi + 1];
            _triangles[ti + 3].position = _verticies[vi + 1];
            _triangles[ti + 4].position = _verticies[vi + _width + 1];
            _triangles[ti + 5].position = _verticies[vi + _width + 2];
        }
    }

    [self calculateNormals];
}

- (void)evolveMesh
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
            float noiseAtPosition = [_noiseMap valueAtPosition:simd_make_int2(w, l)]; // Between -1 and 1
            //            _verticies[i] = (simd_float3) { w, ((noiseAtPosition + 1) / 2) * 20, l };
            _verticies[i] = (simd_float3) { w, 0, l };
        }
    }

    _iteration++;

    [self tesalate];
    [self updateBuffer];
}

- (void)calculateNormals
{
    int triangleCount = [self getVerticies] / 3;
    //    simd_float3* vertexNormals = calloc(triangleCount, sizeof(simd_float3));

    for (int i = 0; i < triangleCount; i++) {
        int normalTriangleIndex  = i * 3;
        simd_float3 vertexIndexA = _triangles[normalTriangleIndex].position;
        simd_float3 vertexIndexB = _triangles[normalTriangleIndex + 1].position;
        simd_float3 vertexIndexC = _triangles[normalTriangleIndex + 2].position;

        simd_float3 normal                         = [self surfaceNormalFromVectorsA:vertexIndexA
                                                           B:vertexIndexB
                                                           C:vertexIndexC];
        _triangles[normalTriangleIndex].normal     = normal;
        _triangles[normalTriangleIndex + 1].normal = normal;
        _triangles[normalTriangleIndex + 2].normal = normal;
    }
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

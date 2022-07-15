//
//  Renderer.m
//  MetalEngine
//
//  Created by Lachlan Russell on 12/11/21.
//

#import "Renderer.h"
#import "PCDRCamera.h"

static const NSUInteger kMaxBuffersInFlight = 3;

static const size_t kAlignedUniformsSize = (sizeof(Uniforms) & ~0xFF) + 0x100;

@implementation Renderer {
    dispatch_semaphore_t _inFlightSemaphore;
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;

    id<MTLBuffer> _dynamicUniformBuffer;
    id<MTLRenderPipelineState> _pipelineState;
    id<MTLDepthStencilState> _depthState;
    id<MTLTexture> _colorMap;
    MTLVertexDescriptor *_mtlVertexDescriptor;

    uint32_t _uniformBufferOffset;

    uint8_t _uniformBufferIndex;

    void *_uniformBufferAddress;

    matrix_float4x4 _projectionMatrix;
    PCDRCamera *_camera;

    Terrain *_mesh;

    float _rotation;
    float _time;
    long int _verticies_count;
}

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view;
{
    self = [super init];
    if (self) {
        _device            = view.device;
        _inFlightSemaphore = dispatch_semaphore_create(kMaxBuffersInFlight);
        [self _loadMetalWithView:view];
        [self _loadAssets];
        simd_float4 cameraInitPosition = { 0, 0, 0, 0 };
        _camera                        = [[PCDRCamera alloc] initWithPosition:cameraInitPosition];
    }

    return self;
}

- (void)_loadMetalWithView:(nonnull MTKView *)view
{
    _mtlVertexDescriptor = [[MTLVertexDescriptor alloc] init];

    _mtlVertexDescriptor.attributes[VertexAttributePosition].format      = MTLVertexFormatFloat3;
    _mtlVertexDescriptor.attributes[VertexAttributePosition].offset      = 0;
    _mtlVertexDescriptor.attributes[VertexAttributePosition].bufferIndex = BufferIndexMeshPositions;

    _mtlVertexDescriptor.attributes[VertexAttributeNormal].format      = MTLVertexFormatFloat3;
    _mtlVertexDescriptor.attributes[VertexAttributeNormal].offset      = sizeof(simd_float3);
    _mtlVertexDescriptor.attributes[VertexAttributeNormal].bufferIndex = BufferIndexMeshPositions;

    _mtlVertexDescriptor.layouts[0].stride       = sizeof(VERTEX);
    _mtlVertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;

    //    _mtlVertexDescriptor.layouts[BufferIndexMeshPositions].stride       = 12;
    //    _mtlVertexDescriptor.layouts[BufferIndexMeshPositions].stepRate     = 1;
    //    _mtlVertexDescriptor.layouts[BufferIndexMeshPositions].stepFunction = MTLVertexStepFunctionPerVertex;
    //
    //    _mtlVertexDescriptor.layouts[BufferIndexMeshGenerics].stride       = 8;
    //    _mtlVertexDescriptor.layouts[BufferIndexMeshGenerics].stepRate     = 1;
    //    _mtlVertexDescriptor.layouts[BufferIndexMeshGenerics].stepFunction = MTLVertexStepFunctionPerVertex;

    id<MTLLibrary> defaultLibrary    = [_device newDefaultLibrary];
    id<MTLFunction> vertexFunction   = [defaultLibrary newFunctionWithName:@"vertexShader"];
    id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader"];

    MTLRenderPipelineDescriptor *pipelineStateDescriptor    = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.label                           = @"MyPipeline";
    pipelineStateDescriptor.vertexFunction                  = vertexFunction;
    pipelineStateDescriptor.fragmentFunction                = fragmentFunction;
    pipelineStateDescriptor.vertexDescriptor                = _mtlVertexDescriptor;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;

    NSError *error = NULL;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                             error:&error];
    if (!_pipelineState) {
        NSLog(@"Failed to created pipeline state, error %@", error);
    }

    NSUInteger uniformBufferSize = kAlignedUniformsSize * kMaxBuffersInFlight;
    _dynamicUniformBuffer        = [_device newBufferWithLength:uniformBufferSize
                                                 options:MTLResourceStorageModeShared];

    _dynamicUniformBuffer.label = @"UniformBuffer";

    _commandQueue = [_device newCommandQueue];
}

- (void)_loadAssets
{
    /// Load assets into metal objects

    //    NSError *error;

    //    MTKMeshBufferAllocator *metalAllocator = [[MTKMeshBufferAllocator alloc]
    //        initWithDevice:_device];
    //
    //    MDLMesh *mdlMesh = [MDLMesh newBoxWithDimensions:(vector_float3){4, 4, 4}
    //                                            segments:(vector_uint3){1, 1, 1}
    //                                        geometryType:MDLGeometryTypeTriangles
    //                                       inwardNormals:NO
    //                                           allocator:metalAllocator];
    //
    //    MDLMesh *mdlMesh = [self createLandscapeWithWidth:1
    //                                               length:1
    //                                            allocator:metalAllocator];
    //
    _mesh = [[Terrain alloc] initWithDevice:_device
                                      width:100
                                     length:100];
    //
    //    [self createLandscapeWithWidth:100
    //                            length:100
    //                            buffer:_mesh];

    //    MDLVertexDescriptor *mdlVertexDescriptor = MTKModelIOVertexDescriptorFromMetal(_mtlVertexDescriptor);
    //
    //    mdlVertexDescriptor.attributes[VertexAttributePosition].name = MDLVertexAttributePosition;
    //    mdlVertexDescriptor.attributes[VertexAttributeTexcoord].name = MDLVertexAttributeTextureCoordinate;
    //
    //    mdlMesh.vertexDescriptor = mdlVertexDescriptor;
    //
    //    _mesh = [[MTKMesh alloc] initWithMesh:mdlMesh
    //                                   device:_device
    //                                    error:&error];
    //
    //    if (!_mesh || error) {
    //        NSLog(@"Error creating MetalKit mesh %@", error.localizedDescription);
    //    }
    //
    //    MTKTextureLoader *textureLoader = [[MTKTextureLoader alloc] initWithDevice:_device];
    //
    //    NSDictionary *textureLoaderOptions =
    //        @{
    //            MTKTextureLoaderOptionTextureUsage : @(MTLTextureUsageShaderRead),
    //            MTKTextureLoaderOptionTextureStorageMode : @(MTLStorageModePrivate)
    //        };
    //
    //    _colorMap = [textureLoader newTextureWithName:@"ColorMap"
    //                                      scaleFactor:0.5
    //                                           bundle:nil
    //                                          options:textureLoaderOptions
    //                                            error:&error];
    //
    //    if (!_colorMap || error) {
    //        NSLog(@"Error creating texture %@", error.localizedDescription);
    //    }
}

- (void)createLandscapeWithWidth:(int)width length:(int)length buffer:(id<MTLBuffer>)buffer
{

    simd_float3 verticies[(width + 1) * (length + 1)];
    _verticies_count = width * length * 6;
    uint16 indicies[_verticies_count];
    simd_float3 triangles[_verticies_count];

    printf("vector_float3 size %lu\n", sizeof(simd_float3));
    printf("Verticies %lu\n", sizeof(verticies));
    printf("Indexes %lu\n", sizeof(indicies));

    GKPerlinNoiseSource *perlinNoise = [[GKPerlinNoiseSource alloc] initWithFrequency:0.05
                                                                          octaveCount:8
                                                                          persistence:0.4
                                                                           lacunarity:1.8
                                                                                 seed:5];

    assert(perlinNoise != NULL);
    GKNoise *noise = [[GKNoise alloc] initWithNoiseSource:perlinNoise];

    GKNoiseMap *noiseMap = [[GKNoiseMap alloc] initWithNoise:noise
                                                        size:simd_make_double2(width, length)
                                                      origin:simd_make_double2(0, 0)
                                                 sampleCount:simd_make_int2(width, length)
                                                    seamless:true];

    // Create Verticies
    for (int i = 0, l = 0; l <= length; l++) {
        for (int w = 0; w <= width; w++, i++) {
            float noiseAtPosition = [noiseMap valueAtPosition:simd_make_int2(w, l)];
            verticies[i]          = (simd_float3) { w, ((noiseAtPosition + 1) / 2) * 20, l }; // noiseAtPosition between -1 and 1. Scale to 0-255
            //            NSLog(@"vector = %f", verticies[i][2]);
        }
    }

    // Create Triangles
    for (int ti = 0, vi = 0, l = 0; l < length; l++, vi++) {
        for (int w = 0; w < width; w++, ti += 6, vi++) {
            triangles[ti]     = verticies[vi];
            triangles[ti + 1] = verticies[vi + width + 1];
            triangles[ti + 2] = verticies[vi + 1];
            triangles[ti + 3] = verticies[vi + 1];
            triangles[ti + 4] = verticies[vi + width + 1];
            triangles[ti + 5] = verticies[vi + width + 2];
        }
    }

    for (int i = 0; i < _verticies_count; i++) {
        //        NSLog(@"triangle %f %f %f", triangles[i][0], triangles[i][1], triangles[i][2]);
    }

    _mesh = [_device newBufferWithBytes:triangles
                                 length:sizeof(triangles)
                                options:MTLResourceOptionCPUCacheModeDefault];
}

- (void)_updateDynamicBufferState
{
    /// Update the state of our uniform buffers before rendering

    _uniformBufferIndex = (_uniformBufferIndex + 1) % kMaxBuffersInFlight;

    _uniformBufferOffset = kAlignedUniformsSize * _uniformBufferIndex;

    _uniformBufferAddress = ((uint8_t *)_dynamicUniformBuffer.contents) + _uniformBufferOffset;
}

- (void)_updateGameState
{
    /// Update any game state before encoding renderint commands to our drawable

    Uniforms *uniforms = (Uniforms *)_uniformBufferAddress;

    uniforms->projectionMatrix = _projectionMatrix;

//    simd_float3 rotationAxis  = { 1, 1, 0 };
    simd_float4x4 modelMatrix = matrix_identity_float4x4; // matrix4x4_rotation(_rotation, rotationAxis);
    uniforms->modelMatrix     = modelMatrix;
    uniforms->modelViewMatrix = matrix_multiply([_camera getViewMatrix], modelMatrix);
    simd_float3x3 normals  = { modelMatrix.columns[0].xyz, modelMatrix.columns[1].xyz, modelMatrix.columns[2].xyz };
    uniforms->normalMatrix = simd_transpose(normals);

    [_mesh evolveMesh];

    _time += .005;
    //    _rotation = sinf(_time);
}

- (void)drawInMTKView:(nonnull MTKView *)view
{
    /// Per frame updates here

    dispatch_semaphore_wait(_inFlightSemaphore, DISPATCH_TIME_FOREVER);

    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label                = @"MyCommand";

    __block dispatch_semaphore_t block_sema = _inFlightSemaphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
        dispatch_semaphore_signal(block_sema);
    }];

    [self _updateDynamicBufferState];

    [self _updateGameState];

    /// Delay getting the currentRenderPassDescriptor until we absolutely need it to avoid
    ///   holding onto the drawable and blocking the display pipeline any longer than necessary
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;

    if (renderPassDescriptor != nil) {

        /// Final pass rendering code here

        id<MTLRenderCommandEncoder> renderEncoder =
            [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"MyRenderEncoder";

        [renderEncoder pushDebugGroup:@"DrawBox"];

        [renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
        [renderEncoder setCullMode:MTLCullModeBack];
        [renderEncoder setRenderPipelineState:_pipelineState];
        //        [renderEncoder setDepthStencilState:_depthState];

        [renderEncoder setVertexBuffer:_dynamicUniformBuffer
                                offset:_uniformBufferOffset
                               atIndex:BufferIndexUniforms];

        [renderEncoder setFragmentBuffer:_dynamicUniformBuffer
                                  offset:_uniformBufferOffset
                                 atIndex:BufferIndexUniforms];

        //        for (NSUInteger bufferIndex = 0; bufferIndex < _mesh.vertexBuffers.count; bufferIndex++) {
        //            MTKMeshBuffer* vertexBuffer = _mesh.vertexBuffers[bufferIndex];
        //            if ((NSNull*)vertexBuffer != [NSNull null]) {
        //                [renderEncoder setVertexBuffer:vertexBuffer.buffer
        //                                        offset:vertexBuffer.offset
        //                                       atIndex:bufferIndex];
        //            }
        //        }
        //
        //        [renderEncoder setFragmentTexture:_colorMap
        //                                  atIndex:TextureIndexColor];
        //
        //        for (MTKSubmesh* submesh in _mesh.submeshes) {
        //            [renderEncoder drawIndexedPrimitives:submesh.primitiveType
        //                                      indexCount:submesh.indexCount
        //                                       indexType:submesh.indexType
        //                                     indexBuffer:submesh.indexBuffer.buffer
        //                               indexBufferOffset:submesh.indexBuffer.offset];
        //        }

        [renderEncoder setVertexBuffer:[_mesh getMesh]
                                offset:0
                               atIndex:BufferIndexMeshPositions];

        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:[_mesh getVerticies]];

        [renderEncoder popDebugGroup];

        [renderEncoder endEncoding];

        [commandBuffer presentDrawable:view.currentDrawable];
    }

    [commandBuffer commit];
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    /// Respond to drawable size or orientation changes here

    float aspect      = size.width / (float)size.height;
    _projectionMatrix = matrix_perspective_right_hand(65.0f * (M_PI / 180.0f), aspect, 0.1f, 300.0f);
}

@end

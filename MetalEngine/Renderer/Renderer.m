//
//  Renderer.m
//  MetalEngine
//
//  Created by Lachlan Russell on 12/11/21.
//

#import "Renderer.h"

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

    float _rotation;

    //    MTKMesh* _mesh;
    id<MTLBuffer> _mesh;
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
    }

    return self;
}

- (void)_loadMetalWithView:(nonnull MTKView *)view
{
    /// Load Metal state objects and initialize renderer dependent view properties
    //    view.depthStencilPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
    //    view.colorPixelFormat        = MTLPixelFormatBGRA8Unorm_sRGB;
    //    view.sampleCount             = 1;

    _mtlVertexDescriptor = [[MTLVertexDescriptor alloc] init];

    _mtlVertexDescriptor.attributes[VertexAttributePosition].format      = MTLVertexFormatFloat3;
    _mtlVertexDescriptor.attributes[VertexAttributePosition].offset      = 0;
    _mtlVertexDescriptor.attributes[VertexAttributePosition].bufferIndex = BufferIndexMeshPositions;

    _mtlVertexDescriptor.layouts[0].stride = sizeof(MTLVertexFormatFloat3);
    //
    //    _mtlVertexDescriptor.attributes[VertexAttributeTexcoord].format      = MTLVertexFormatFloat2;
    //    _mtlVertexDescriptor.attributes[VertexAttributeTexcoord].offset      = 0;
    //    _mtlVertexDescriptor.attributes[VertexAttributeTexcoord].bufferIndex = BufferIndexMeshGenerics;
    //
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

    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.label                        = @"MyPipeline";
    //    pipelineStateDescriptor.sampleCount                     = view.sampleCount;
    pipelineStateDescriptor.vertexFunction                  = vertexFunction;
    pipelineStateDescriptor.fragmentFunction                = fragmentFunction;
    pipelineStateDescriptor.vertexDescriptor                = _mtlVertexDescriptor;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;
    //    pipelineStateDescriptor.depthAttachmentPixelFormat      = view.depthStencilPixelFormat;
    //    pipelineStateDescriptor.stencilAttachmentPixelFormat    = view.depthStencilPixelFormat;

    NSError *error = NULL;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                             error:&error];
    if (!_pipelineState) {
        NSLog(@"Failed to created pipeline state, error %@", error);
    }

    //    MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
    //    depthStateDesc.depthCompareFunction       = MTLCompareFunctionLess;
    //    depthStateDesc.depthWriteEnabled          = YES;
    //    _depthState                               = [_device newDepthStencilStateWithDescriptor:depthStateDesc];

    NSUInteger uniformBufferSize = kAlignedUniformsSize * kMaxBuffersInFlight;

    _dynamicUniformBuffer = [_device newBufferWithLength:uniformBufferSize
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
    [self createLandscapeWithWidth:100
                            length:100
                            buffer:_mesh];

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

    printf("vector_float3 size %lu\n", sizeof(vector_float3));
    printf("Verticies %lu\n", sizeof(verticies));
    printf("Indexes %lu\n", sizeof(indicies));
    
    GKPerlinNoiseSource *perlinNoise = [[GKPerlinNoiseSource alloc] initWithFrequency:25
                                                                           octaveCount:4
                                                                           persistence:0.5
                                                                            lacunarity:1.87
                                                                                  seed:3];

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
            verticies[i] = (vector_float3) { w, l, noiseAtPosition };
//            NSLog(@"vector = %d, %d, %f", w, l, noiseAtPosition);
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

    simd_float3 rotationAxis    = { 1, 1, 0 };
    matrix_float4x4 modelMatrix = matrix4x4_rotation(_rotation, rotationAxis);
    matrix_float4x4 viewMatrix  = matrix4x4_translation(-50, -50, -100.0);

    uniforms->modelViewMatrix = matrix_multiply(viewMatrix, modelMatrix);

    _rotation += .005;
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

        [renderEncoder setVertexBuffer:_mesh
                                offset:0
                               atIndex:0];

        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:_verticies_count];

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
    _projectionMatrix = matrix_perspective_right_hand(65.0f * (M_PI / 180.0f), aspect, 0.1f, 100.0f);
}

#pragma mark Matrix Math Utilities

matrix_float4x4 matrix4x4_translation(float tx, float ty, float tz)
{
    return (matrix_float4x4) {
        {{ 1, 0, 0, 0 },
         { 0, 1, 0, 0 },
         { 0, 0, 1, 0 },
         { tx, ty, tz, 1 }}
    };
}

static matrix_float4x4 matrix4x4_rotation(float radians, vector_float3 axis)
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

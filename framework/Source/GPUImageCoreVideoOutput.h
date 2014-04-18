#import "GPUImageFilter.h"

extern NSString *const kGPUImageColorSwizzlingFragmentShaderString;

@interface GPUImageCoreVideoOutput : NSObject <GPUImageInput>
{
    CVOpenGLESTextureCacheRef coreVideoTextureCache;
    CVPixelBufferRef renderTarget;
    CVOpenGLESTextureRef renderTexture;
    
    CGSize videoSize;
    GPUImageRotationMode inputRotation;
}

@property(nonatomic) BOOL enabled;
@property(readwrite, nonatomic) GPUVector4 backgroundColor;

// Initialization and teardown
- (id)initWithVideoSize:(CGSize)newSize;

@end

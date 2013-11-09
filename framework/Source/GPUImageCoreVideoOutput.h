#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "GPUImageContext.h"

extern NSString *const kGPUImageColorSwizzlingFragmentShaderString;

@interface GPUImageCoreVideoOutput : NSObject <GPUImageInput>
{
    CVOpenGLESTextureCacheRef coreVideoTextureCache;
    CVPixelBufferRef renderTarget;
    CVOpenGLESTextureRef renderTexture;
    
    CGSize videoSize;
    GPUImageRotationMode inputRotation;
    
    __unsafe_unretained id<GPUImageTextureDelegate> textureDelegate;
}

@property(nonatomic) BOOL enabled;

// Initialization and teardown
- (id)initWithVideoSize:(CGSize)newSize;

@end

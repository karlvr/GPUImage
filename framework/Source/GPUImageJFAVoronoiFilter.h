#import "GPUImageFilter.h"

@interface GPUImageJFAVoronoiFilter : GPUImageFilter
{
    GLuint secondFilterOutputTexture;
    GLuint secondFilterFramebuffer;
    
    
    GPUImageUniform sampleStepUniform;
    GPUImageUniform sizeUniform;
    NSUInteger numPasses;
    
}

@property (nonatomic, readwrite) CGSize sizeInPixels;

@end
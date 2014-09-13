#import "GPUImageAverageColor.h"

@interface GPUImageLuminosity : GPUImageAverageColor
{
    GPUImageGLProgram *secondFilterProgram;
    GLint secondFilterPositionAttribute, secondFilterTextureCoordinateAttribute;
    GPUImageUniform secondFilterInputTextureUniform, secondFilterInputTextureUniform2;
    GPUImageUniform secondFilterTexelWidthUniform, secondFilterTexelHeightUniform;
}

// This block is called on the completion of color averaging for a frame
@property(nonatomic, copy) void(^luminosityProcessingFinishedBlock)(CGFloat luminosity, CMTime frameTime);

- (void)extractLuminosityAtFrameTime:(CMTime)frameTime;
- (void)initializeSecondaryAttributes;

@end

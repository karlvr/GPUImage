#import "GPUImageFilter.h"

@interface GPUImageTwoPassFilter : GPUImageFilter
{
    GPUImageFramebuffer *secondOutputFramebuffer;

    GPUImageGLProgram *secondFilterProgram;
    GLint secondFilterPositionAttribute, secondFilterTextureCoordinateAttribute;
    GPUImageUniform secondFilterInputTextureUniform, secondFilterInputTextureUniform2;
    
    NSMutableDictionary *secondProgramUniformStateRestorationBlocks;
}

// Initialization and teardown
- (id)initWithFirstStageVertexShaderFromString:(NSString *)firstStageVertexShaderString firstStageFragmentShaderFromString:(NSString *)firstStageFragmentShaderString secondStageVertexShaderFromString:(NSString *)secondStageVertexShaderString secondStageFragmentShaderFromString:(NSString *)secondStageFragmentShaderString;
- (id)initWithFirstStageFragmentShaderFromString:(NSString *)firstStageFragmentShaderString secondStageFragmentShaderFromString:(NSString *)secondStageFragmentShaderString;
- (void)initializeSecondaryAttributes;

@end

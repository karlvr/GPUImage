#import "GPUImageUnpremultiplyAlphaFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageUnpremultiplyAlphaFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     gl_FragColor = vec4(dot(1.0 / textureColor.a, textureColor.rgb), textureColor.a);
 }
 );
#else
NSString *const kGPUImageUnpremultiplyAlphaFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     gl_FragColor = vec4(dot(1.0 / textureColor.a, textureColor.rgb), textureColor.a);
 }
 );
#endif

@implementation GPUImageUnpremultiplyAlphaFilter

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageUnpremultiplyAlphaFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

@end


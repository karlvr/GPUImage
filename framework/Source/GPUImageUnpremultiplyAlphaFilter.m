#import "GPUImageUnpremultiplyAlphaFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageUnpremultiplyAlphaFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     if (textureColor.a > 0) {
         gl_FragColor = vec4(textureColor.rgb / textureColor.a, textureColor.a);
     } else {
         gl_FragColor = textureColor;
     }
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
     
     if (textureColor.a > 0) {
         gl_FragColor = vec4(textureColor.rgb / textureColor.a, textureColor.a);
     } else {
         gl_FragColor = textureColor;
     }
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


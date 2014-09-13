#import "GPUImageFilter.h"

@interface GPUImageColorPackingFilter : GPUImageFilter
{
    GPUImageUniform texelWidthUniform, texelHeightUniform;
    
    CGFloat texelWidth, texelHeight;
}

@end

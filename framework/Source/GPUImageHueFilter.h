
#import "GPUImageFilter.h"

@interface GPUImageHueFilter : GPUImageFilter
{
    GPUImageUniform hueAdjustUniform;
    
}
@property (nonatomic, readwrite) CGFloat hue;

@end

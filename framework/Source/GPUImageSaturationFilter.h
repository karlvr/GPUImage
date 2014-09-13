#import "GPUImageFilter.h"

/** Adjusts the saturation of an image
 */
@interface GPUImageSaturationFilter : GPUImageFilter
{
    GPUImageUniform saturationUniform;
}

/** Saturation ranges from 0.0 (fully desaturated) to 2.0 (max saturation), with 1.0 as the normal level
 */
@property(readwrite, nonatomic) CGFloat saturation; 

@end

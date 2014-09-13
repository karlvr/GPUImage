#import "GPUImageFilter.h"

/** Adjusts the contrast of the image
 */
@interface GPUImageContrastFilter : GPUImageFilter
{
    GPUImageUniform contrastUniform;
}

/** Contrast ranges from 0.0 to 4.0 (max contrast), with 1.0 as the normal level
 */
@property(readwrite, nonatomic) CGFloat contrast; 

@end

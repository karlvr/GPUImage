#import "GPUImageGaussianBlurFilter.h"

@interface GPUImageBilateralFilter : GPUImageGaussianBlurFilter
{
    GPUImageUniform firstDistanceNormalizationFactorUniform;
    GPUImageUniform secondDistanceNormalizationFactorUniform;
}
// A normalization factor for the distance between central color and sample color.
@property(nonatomic, readwrite) CGFloat distanceNormalizationFactor;
@end

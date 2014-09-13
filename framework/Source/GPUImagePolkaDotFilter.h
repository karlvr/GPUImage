#import "GPUImagePixellateFilter.h"

@interface GPUImagePolkaDotFilter : GPUImagePixellateFilter
{
    GPUImageUniform dotScalingUniform;
}

@property(readwrite, nonatomic) CGFloat dotScaling;

@end

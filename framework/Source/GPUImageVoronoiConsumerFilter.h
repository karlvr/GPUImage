#import "GPUImageTwoInputFilter.h"

@interface GPUImageVoronoiConsumerFilter : GPUImageTwoInputFilter 
{
    GPUImageUniform sizeUniform;
}

@property (nonatomic, readwrite) CGSize sizeInPixels;

@end

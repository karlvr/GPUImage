#import "GPUImageFramebufferPool.h"

@interface GPUImageFramebufferIdleTrackingPool : GPUImageFramebufferPool

@property (nonatomic) NSUInteger maxIdleCount;
@property (nonatomic) NSTimeInterval maxIdleInterval;
@property (nonatomic) NSTimeInterval idleResetInterval;

@end

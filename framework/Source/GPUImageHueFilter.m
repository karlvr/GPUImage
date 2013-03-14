
#import "GPUImageHueFilter.h"

@implementation GPUImageHueFilter
@synthesize hue;

- (id)init
{
    if(! (self = [super init]) )
    {
        return nil;
    }
    
    self.hue = 90;
    
    return self;
}

- (void)setHue:(CGFloat)newHue
{
    [self reset];
    [self rotateHue:newHue];
}

@end

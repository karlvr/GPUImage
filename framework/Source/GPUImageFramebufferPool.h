#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "GPUImageFramebuffer.h"

@interface GPUImageFramebufferPool : NSObject {
    NSMutableArray *_objects;
}

@property (strong, nonatomic) NSString *name;

- (id)popObject;
- (void)pushObject:(id)object;
- (void)maintain:(BOOL)force;

@end

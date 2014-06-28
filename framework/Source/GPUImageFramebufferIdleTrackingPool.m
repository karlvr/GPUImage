//
//  GPUImageFramebufferIdleTrackingPool.m
//  GPUImage
//
//  Created by Karl von Randow on 28/06/14.
//  Copyright (c) 2014 Brad Larson. All rights reserved.
//

#import "GPUImageFramebufferIdleTrackingPool.h"

#define DEBUG_FRAMEBUFFER_POOL 0

@implementation GPUImageFramebufferIdleTrackingPool {
    NSUInteger _idleCount;
    NSTimeInterval _idleSince;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _idleCount = 0;
        _idleSince = CACurrentMediaTime();
        
        self.maxIdleCount = 0;
        self.maxIdleInterval = 2;
        self.idleResetInterval = 5;
    }
    return self;
}

- (id)popObject
{
    id object = [super popObject];
    if (object) {
        /* Update _idleFramebuffersCount */
        NSUInteger framebuffersInCache = _objects.count;
        NSTimeInterval now = CACurrentMediaTime();
        
        if (framebuffersInCache < _idleCount) {
            /* We have fewer framebuffers now, so reduce idle count, but don't need to reset time as this
             count has been idle since _idleFramebuffersSince.
             */
            _idleCount = framebuffersInCache;
        } else if (now - _idleSince > _idleResetInterval) {
            _idleCount = framebuffersInCache;
            _idleSince = now;
        }
    }
    return object;
}

- (void)pushObject:(id)object
{
    NSTimeInterval now = CACurrentMediaTime();
    if (_idleCount > _maxIdleCount && now - _idleSince > _maxIdleInterval) {
        /* Drop this object, as we have spare ones in the last interval */
#if DEBUG_FRAMEBUFFER_POOL
        NSLog(@"*** %@: Dropped object", self.name);
#endif
        return;
    }
    
    [super pushObject:object];
    
    /* Check if we should reset _idleCount */
    if (now - _idleSince > _idleResetInterval || _idleCount == 0) {
        _idleCount = _objects.count;
        _idleSince = now;
    }
}

- (void)maintain:(BOOL)force
{
    NSTimeInterval now = CACurrentMediaTime();
    
    /* Check if we have framebuffers in the cache that haven't been used in the last interval */
    if (_idleCount > _maxIdleCount && (now - _idleSince > _maxIdleInterval || force)) {
        /* Throw away the number of framebuffers that haven't been used */
        NSUInteger framebuffersInCache = _objects.count;
        NSUInteger toRemove = MIN(_idleCount - _maxIdleCount, framebuffersInCache);
        NSRange removeRange = NSMakeRange(framebuffersInCache - toRemove, toRemove);
        [_objects removeObjectsInRange:removeRange];
        
        /* Restart the idle tracking with the remaining framebuffers in the cache */
        _idleCount = framebuffersInCache - toRemove;
        _idleSince = now;
        
#if DEBUG_FRAMEBUFFER_POOL
        NSLog(@"*** %@: Reduced cache to %lu", self.name, (unsigned long) _objects.count);
#endif
    } else {
        /* Check if we should reset _idleFramebuffers */
        if (now - _idleSince > _idleResetInterval || _idleCount == 0) {
            _idleCount = _objects.count;
            _idleSince = now;
        }
    }
}

@end

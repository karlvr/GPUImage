//
//  GPUImageFramebufferPool.m
//  GPUImage
//
//  Created by Karl von Randow on 28/06/14.
//  Copyright (c) 2014 Brad Larson. All rights reserved.
//

#import "GPUImageFramebufferPool.h"

@implementation GPUImageFramebufferPool

- (instancetype)init
{
    self = [super init];
    if (self) {
        _objects = [NSMutableArray array];
    }
    return self;
}

- (id)popObject
{
    id object = [_objects lastObject];
    if (object) {
        [_objects removeLastObject];
    }
    return object;
}

- (void)pushObject:(id)object
{
    [_objects addObject:object];
}

- (void)maintain:(BOOL)force
{
    if (force) {
        [_objects removeAllObjects];
    }
}

@end

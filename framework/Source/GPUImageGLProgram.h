//
//  GPUImageGLProgram.h
//  GPUImage
//
//  Created by Karl von Randow on 10/09/14.
//  Copyright (c) 2014 Brad Larson. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface GPUImageGLProgram : NSObject

- (id)initWithVertexShaderString:(NSString *)vShaderString
            fragmentShaderString:(NSString *)fShaderString;

- (void)addAttribute:(NSString *)attributeName;
- (GLuint)attributeIndex:(NSString *)attributeName;
- (GLuint)uniformIndex:(NSString *)uniformName;
- (BOOL)link;
- (void)use;
- (NSString *)vertexShaderLog;
- (NSString *)fragmentShaderLog;
- (NSString *)programLog;

@end

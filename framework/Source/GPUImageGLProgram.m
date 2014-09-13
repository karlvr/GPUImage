//
//  GPUImageGLProgram.m
//  GPUImage
//
//  Created by Karl von Randow on 10/09/14.
//  Copyright (c) 2014 Brad Larson. All rights reserved.
//

#import "GPUImageGLProgram.h"

static NSMutableDictionary *GPUImageGLProgramCache;

@implementation GPUImageGLProgram {
    GLuint _vertexProgram, _fragmentProgram, _ppo;
    NSMutableArray  *_attributes;
}

+ (void)initialize
{
    GPUImageGLProgramCache = [NSMutableDictionary dictionary];
}

- (id)initWithVertexShaderString:(NSString *)vShaderString
            fragmentShaderString:(NSString *)fShaderString
{
    self = [self init];
    if (self) {
        _vertexProgram = [self programForSourceString:vShaderString ofType:GL_VERTEX_SHADER];
        _fragmentProgram = [self programForSourceString:fShaderString ofType:GL_FRAGMENT_SHADER];
        
        // Construct a program pipeline object and configure it to use the shaders
        glGenProgramPipelinesEXT(1, &_ppo);
        glBindProgramPipelineEXT(_ppo);
        glUseProgramStagesEXT(_ppo, GL_VERTEX_SHADER_BIT_EXT, _vertexProgram);
        glUseProgramStagesEXT(_ppo, GL_FRAGMENT_SHADER_BIT_EXT, _fragmentProgram);
    }
    return self;
}

- (void)addAttribute:(NSString *)attributeName
{
    if (![_attributes containsObject:attributeName])
    {
        [_attributes addObject:attributeName];
        glBindAttribLocation(_ppo,
                             (GLuint)[_attributes indexOfObject:attributeName],
                             [attributeName UTF8String]);
    }
}

- (GLuint)attributeIndex:(NSString *)attributeName
{
    return (GLuint)[_attributes indexOfObject:attributeName];
}

- (GLuint)uniformIndex:(NSString *)uniformName
{
    return glGetUniformLocation(_ppo, [uniformName UTF8String]);
}

- (BOOL)link
{
    return YES;
}

- (void)use
{
    glBindProgramPipelineEXT(_ppo);
}

- (NSString *)vertexShaderLog
{
    return nil;
}

- (NSString *)fragmentShaderLog
{
    return nil;
}

- (NSString *)programLog
{
    return nil;
}

#pragma mark - Private

- (GLuint)programForSourceString:(NSString *)source ofType:(GLenum)type
{
    NSString * const cacheKey = [NSString stringWithFormat:@"%i:%@", type, source];
    
    NSNumber *n = GPUImageGLProgramCache[cacheKey];
    if (n) {
        return (GLuint) [n unsignedLongValue];
    } else {
        const GLchar *sourceChars = (GLchar *)[source UTF8String];
        
        GLuint program = glCreateShaderProgramvEXT(type, 1, &sourceChars);
        GPUImageGLProgramCache[cacheKey] = @(program);
        
        return program;
    }
}

@end

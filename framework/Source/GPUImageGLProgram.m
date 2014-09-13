//
//  GPUImageGLProgram.m
//  GPUImage
//
//  Created by Karl von Randow on 10/09/14.
//  Copyright (c) 2014 Brad Larson. All rights reserved.
//

#import "GPUImageGLProgram.h"

GPUImageUniform GPUImageUniformInvalid = (GPUImageUniform) { -1, 0 };

GPUImageUniform GPUImageUniformMake(GLint location, GLuint program) {
    return (GPUImageUniform) { location, program };
}

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
        _attributes = [NSMutableArray array];
        _vertexProgram = [self programForSourceString:vShaderString ofType:GL_VERTEX_SHADER];
        _fragmentProgram = [self programForSourceString:fShaderString ofType:GL_FRAGMENT_SHADER];
        
        NSLog(@"vertexProgram = %i fragmentProgram = %i", _vertexProgram, _fragmentProgram);
    }
    return self;
}

- (void)addAttribute:(NSString *)attributeName
{
    if (![_attributes containsObject:attributeName]) {
        [_attributes addObject:attributeName];
        GLuint index = (GLuint)[_attributes indexOfObject:attributeName];
        glBindAttribLocation(_vertexProgram,
                             index,
                             [attributeName UTF8String]);
        
        NSLog(@"Bind attribute %@ at %i", attributeName, index);
    }
}

- (GLuint)attributeIndex:(NSString *)attributeName
{
    return (GLuint)[_attributes indexOfObject:attributeName];
}

- (int)uniformIndex:(NSString *)uniformName forProgram:(GLenum)programType
{
    const GLuint program = programType == GL_VERTEX_SHADER ? _vertexProgram : _fragmentProgram;
    
    return glGetUniformLocation(program, [uniformName UTF8String]);
}

- (GPUImageUniform)uniformIndex:(NSString *)uniformName
{
    int uniformLocation = [self uniformIndex:uniformName forProgram:GL_VERTEX_SHADER];
    if (uniformLocation != -1) {
        NSLog(@"found vertex uniform location for %@ is %i", uniformName, uniformLocation);
        return GPUImageUniformMake(uniformLocation, _vertexProgram);
    }
    
    uniformLocation = [self uniformIndex:uniformName forProgram:GL_FRAGMENT_SHADER];
    if (uniformLocation != -1) {
        NSLog(@"found fragment uniform location for %@ is %i", uniformName, uniformLocation);
        return GPUImageUniformMake(uniformLocation, _fragmentProgram);
    }
    
    return GPUImageUniformInvalid;
}

- (BOOL)link
{
    
    // Construct a program pipeline object and configure it to use the shaders
    glGenProgramPipelinesEXT(1, &_ppo);
    glBindProgramPipelineEXT(_ppo);
    glUseProgramStagesEXT(_ppo, GL_VERTEX_SHADER_BIT_EXT, _vertexProgram);
    glUseProgramStagesEXT(_ppo, GL_FRAGMENT_SHADER_BIT_EXT, _fragmentProgram);
    glValidateProgramPipelineEXT(_ppo);
    
    GLint len = 0;
    glGetProgramPipelineivEXT(_ppo, GL_INFO_LOG_LENGTH, &len);
    NSLog(@"Log length %i", len);
    if (len > 0) {
        GLchar log[len];
        glGetProgramPipelineInfoLogEXT(_ppo, len, &len, log);
        NSLog(@"Error: %s", log);
    }
    
    GLint status = 0;
    glGetProgramPipelineivEXT(_ppo, GL_VALIDATE_STATUS, &status);
    
    if (status == 0) {
        NSLog(@"Linked PPO %i", _ppo);
    } else {
        NSLog(@"Failed to link PPO: %i", status);
        
    }
    
    _initialized = YES;
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
        NSLog(@"FROM CACHE");
        return (GLuint) [n unsignedLongValue];
    } else {
        NSLog(@"COMPILING");
        const GLchar *sourceChars = (GLchar *)[source UTF8String];
        
        GLuint program = glCreateShaderProgramvEXT(type, 1, &sourceChars);
        GPUImageGLProgramCache[cacheKey] = @(program);
        
        return program;
    }
}

@end

inline void GPUImageglUniform1f (GPUImageUniform uniform, GLfloat x) {
    glProgramUniform1fEXT(uniform.program, uniform.location, x);
}

inline void GPUImageglUniform1fv (GPUImageUniform uniform, GLsizei count, const GLfloat* v) {
    glProgramUniform1fvEXT(uniform.program, uniform.location, count, v);
}

inline void GPUImageglUniform1i (GPUImageUniform uniform, GLint x) {
    glProgramUniform1iEXT(uniform.program, uniform.location, x);
}

inline void GPUImageglUniform1iv (GPUImageUniform uniform, GLsizei count, const GLint* v) {
    glProgramUniform1ivEXT(uniform.program, uniform.location, count, v);
}

inline void GPUImageglUniform2f (GPUImageUniform uniform, GLfloat x, GLfloat y) {
    glProgramUniform2fEXT(uniform.program, uniform.location, x, y);
}

inline void GPUImageglUniform2fv (GPUImageUniform uniform, GLsizei count, const GLfloat* v) {
    glProgramUniform2fvEXT(uniform.program, uniform.location, count, v);
}

inline void GPUImageglUniform2i (GPUImageUniform uniform, GLint x, GLint y) {
    glProgramUniform2iEXT(uniform.program, uniform.location, x, y);
}

inline void GPUImageglUniform2iv (GPUImageUniform uniform, GLsizei count, const GLint* v) {
    glProgramUniform2ivEXT(uniform.program, uniform.location, count, v);
}

inline void GPUImageglUniform3f (GPUImageUniform uniform, GLfloat x, GLfloat y, GLfloat z) {
    glProgramUniform3fEXT(uniform.program, uniform.location, x, y, z);
}

inline void GPUImageglUniform3fv (GPUImageUniform uniform, GLsizei count, const GLfloat* v) {
    glProgramUniform3fvEXT(uniform.program, uniform.location, count, v);
}

inline void GPUImageglUniform3i (GPUImageUniform uniform, GLint x, GLint y, GLint z) {
    glProgramUniform3iEXT(uniform.program, uniform.location, x, y, z);
}

inline void GPUImageglUniform3iv (GPUImageUniform uniform, GLsizei count, const GLint* v) {
    glProgramUniform3ivEXT(uniform.program, uniform.location, count, v);
}

inline void GPUImageglUniform4f (GPUImageUniform uniform, GLfloat x, GLfloat y, GLfloat z, GLfloat w) {
    glProgramUniform4fEXT(uniform.program, uniform.location, x, y, z, w);
}

inline void GPUImageglUniform4fv (GPUImageUniform uniform, GLsizei count, const GLfloat* v) {
    glProgramUniform4fvEXT(uniform.program, uniform.location, count, v);
}

inline void GPUImageglUniform4i (GPUImageUniform uniform, GLint x, GLint y, GLint z, GLint w) {
    glProgramUniform4iEXT(uniform.program, uniform.location, x, y, z, w);
}

inline void GPUImageglUniform4iv (GPUImageUniform uniform, GLsizei count, const GLint* v) {
    glProgramUniform4ivEXT(uniform.program, uniform.location, count, v);
}

inline void GPUImageglUniformMatrix2fv (GPUImageUniform uniform, GLsizei count, GLboolean transpose, const GLfloat* value) {
    glProgramUniformMatrix2fvEXT(uniform.program, uniform.location, count, transpose, value);
}

inline void GPUImageglUniformMatrix3fv (GPUImageUniform uniform, GLsizei count, GLboolean transpose, const GLfloat* value) {
    glProgramUniformMatrix3fvEXT(uniform.program, uniform.location, count, transpose, value);
}

inline void GPUImageglUniformMatrix4fv (GPUImageUniform uniform, GLsizei count, GLboolean transpose, const GLfloat* value) {
    glProgramUniformMatrix4fvEXT(uniform.program, uniform.location, count, transpose, value);
}

@implementation NSValue (GPUImageUniform)

+ (NSValue *)valueWithGPUImageUniform:(GPUImageUniform)uniform
{
    return [NSValue valueWithBytes:&uniform objCType:@encode(GPUImageUniform)];
}

- (GPUImageUniform)GPUImageUniformValue
{
    if (strcmp([self objCType], @encode(GPUImageUniform))) {
        GPUImageUniform uniform;
        [self getValue:&uniform];
        return uniform;
    } else {
        return GPUImageUniformInvalid;
    }
}

@end

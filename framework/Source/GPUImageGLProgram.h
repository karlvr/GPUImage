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

typedef struct {
    GLint location;
    GLuint program;
} GPUImageUniform;

@class GPUImageGLProgram;

extern GPUImageUniform GPUImageUniformInvalid;
extern GPUImageUniform GPUImageUniformMake(GLint location, GLuint program);

extern void GPUImageglUniform1f (GPUImageUniform uniform, GLfloat x)  __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_3_0);
extern void GPUImageglUniform1fv (GPUImageUniform uniform, GLsizei count, const GLfloat* v)  __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_3_0);
extern void GPUImageglUniform1i (GPUImageUniform uniform, GLint x)  __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_3_0);
extern void GPUImageglUniform1iv (GPUImageUniform uniform, GLsizei count, const GLint* v)  __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_3_0);
extern void GPUImageglUniform2f (GPUImageUniform uniform, GLfloat x, GLfloat y)  __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_3_0);
extern void GPUImageglUniform2fv (GPUImageUniform uniform, GLsizei count, const GLfloat* v)  __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_3_0);
extern void GPUImageglUniform2i (GPUImageUniform uniform, GLint x, GLint y)  __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_3_0);
extern void GPUImageglUniform2iv (GPUImageUniform uniform, GLsizei count, const GLint* v)  __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_3_0);
extern void GPUImageglUniform3f (GPUImageUniform uniform, GLfloat x, GLfloat y, GLfloat z)  __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_3_0);
extern void GPUImageglUniform3fv (GPUImageUniform uniform, GLsizei count, const GLfloat* v)  __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_3_0);
extern void GPUImageglUniform3i (GPUImageUniform uniform, GLint x, GLint y, GLint z)  __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_3_0);
extern void GPUImageglUniform3iv (GPUImageUniform uniform, GLsizei count, const GLint* v)  __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_3_0);
extern void GPUImageglUniform4f (GPUImageUniform uniform, GLfloat x, GLfloat y, GLfloat z, GLfloat w)  __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_3_0);
extern void GPUImageglUniform4fv (GPUImageUniform uniform, GLsizei count, const GLfloat* v)  __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_3_0);
extern void GPUImageglUniform4i (GPUImageUniform uniform, GLint x, GLint y, GLint z, GLint w)  __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_3_0);
extern void GPUImageglUniform4iv (GPUImageUniform uniform, GLsizei count, const GLint* v)  __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_3_0);
extern void GPUImageglUniformMatrix2fv (GPUImageUniform uniform, GLsizei count, GLboolean transpose, const GLfloat* value)  __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_3_0);
extern void GPUImageglUniformMatrix3fv (GPUImageUniform uniform, GLsizei count, GLboolean transpose, const GLfloat* value)  __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_3_0);
extern void GPUImageglUniformMatrix4fv (GPUImageUniform uniform, GLsizei count, GLboolean transpose, const GLfloat* value)  __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_3_0);


@interface GPUImageGLProgram : NSObject

- (id)initWithVertexShaderString:(NSString *)vShaderString
            fragmentShaderString:(NSString *)fShaderString;

@property (readonly, nonatomic) BOOL initialized;
@property (readonly, nonatomic) GLuint vertexProgram;
@property (readonly, nonatomic) GLuint fragmentProgram;

- (void)addAttribute:(NSString *)attributeName;
- (GLuint)attributeIndex:(NSString *)attributeName;
- (int)uniformIndex:(NSString *)uniformName forProgram:(GLenum)programType;
- (GPUImageUniform)uniformIndex:(NSString *)uniformName;
- (BOOL)link;
- (void)use;

- (NSString *)vertexShaderLog;
- (NSString *)fragmentShaderLog;
- (NSString *)programLog;

@end

@interface NSValue (GPUImageUniform)

+ (NSValue *)valueWithGPUImageUniform:(GPUImageUniform)uniform;
- (GPUImageUniform)GPUImageUniformValue;

@end
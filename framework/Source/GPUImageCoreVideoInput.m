//
//  GPUImageCoreVideoInput.m
//  GPUImage
//
//  Created by Karl von Randow on 3/11/13.
//  Copyright (c) 2013 Brad Larson. All rights reserved.
//

#import "GPUImageCoreVideoInput.h"

#import "GPUImageFilter.h"

#define INITIALFRAMESTOIGNOREFORBENCHMARK 5

// Color Conversion Constants (YUV to RGB) including adjustment from 16-235/16-240 (video range)

// BT.601, which is the standard for SDTV.
const GLfloat kColorConversion601[] = {
    1.164,  1.164, 1.164,
    0.0, -0.392, 2.017,
    1.596, -0.813,   0.0,
};

// BT.709, which is the standard for HDTV.
const GLfloat kColorConversion709[] = {
    1.164,  1.164, 1.164,
    0.0, -0.213, 2.112,
    1.793, -0.533,   0.0,
};

NSString *const kGPUImageYUVVideoRangeConversionForRGFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D luminanceTexture;
 uniform sampler2D chrominanceTexture;
 uniform mediump mat3 colorConversionMatrix;
 
 void main()
 {
     mediump vec3 yuv;
     lowp vec3 rgb;
     
     yuv.x = texture2D(luminanceTexture, textureCoordinate).r;
     yuv.yz = texture2D(chrominanceTexture, textureCoordinate).rg - vec2(0.5, 0.5);
     rgb = colorConversionMatrix * yuv;
     
     gl_FragColor = vec4(rgb, 1);
 }
 );

NSString *const kGPUImageYUVVideoRangeConversionForLAFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D luminanceTexture;
 uniform sampler2D chrominanceTexture;
 uniform mediump mat3 colorConversionMatrix;
 
 void main()
 {
     mediump vec3 yuv;
     lowp vec3 rgb;
     
     yuv.x = texture2D(luminanceTexture, textureCoordinate).r;
     yuv.yz = texture2D(chrominanceTexture, textureCoordinate).ra - vec2(0.5, 0.5);
     rgb = colorConversionMatrix * yuv;
     
     gl_FragColor = vec4(rgb, 1);
 }
 );

@interface GPUImageCoreVideoInput () {
    
    GLProgram *yuvConversionProgram;
    GLint yuvConversionPositionAttribute, yuvConversionTextureCoordinateAttribute;
    GLint yuvConversionLuminanceTextureUniform, yuvConversionChrominanceTextureUniform;
    GLint yuvConversionMatrixUniform;
    GLuint yuvConversionFramebuffer;
    const GLfloat *_preferredConversion;
    
    int imageBufferWidth, imageBufferHeight;
}

- (void)convertYUVToRGBOutput;
- (void)setYUVConversionFBO;

@end
    
@implementation GPUImageCoreVideoInput

@synthesize runBenchmark = _runBenchmark;
@synthesize outputRotation = outputRotation;
@synthesize capturePaused = capturePaused;
@synthesize delegate = _delegate;

- (id)initWithCaptureAsYUV:(BOOL)aCaptureAsYUV
{
    self = [super init];
    if (self) {
        _runBenchmark = NO;
        outputRotation = kGPUImageNoRotation;
        capturePaused = NO;
        captureAsYUV = aCaptureAsYUV;
        
        frameRenderingSemaphore = dispatch_semaphore_create(1);
        
        _preferredConversion = kColorConversion709;
        runSynchronouslyOnVideoProcessingQueue(^{
            
            if (captureAsYUV)
            {
                [GPUImageContext useImageProcessingContext];
                //            if ([GPUImageContext deviceSupportsRedTextures])
                //            {
                //                yuvConversionProgram = [[GPUImageContext sharedImageProcessingContext] programForVertexShaderString:kGPUImageVertexShaderString fragmentShaderString:kGPUImageYUVVideoRangeConversionForRGFragmentShaderString];
                //            }
                //            else
                //            {
                yuvConversionProgram = [[GPUImageContext sharedImageProcessingContext] programForVertexShaderString:kGPUImageVertexShaderString fragmentShaderString:kGPUImageYUVVideoRangeConversionForLAFragmentShaderString];
                //            }
                
                if (!yuvConversionProgram.initialized)
                {
                    [yuvConversionProgram addAttribute:@"position"];
                    [yuvConversionProgram addAttribute:@"inputTextureCoordinate"];
                    
                    if (![yuvConversionProgram link])
                    {
                        NSString *progLog = [yuvConversionProgram programLog];
                        NSLog(@"Program link log: %@", progLog);
                        NSString *fragLog = [yuvConversionProgram fragmentShaderLog];
                        NSLog(@"Fragment shader compile log: %@", fragLog);
                        NSString *vertLog = [yuvConversionProgram vertexShaderLog];
                        NSLog(@"Vertex shader compile log: %@", vertLog);
                        yuvConversionProgram = nil;
                        NSAssert(NO, @"Filter shader link failed");
                    }
                }
                
                yuvConversionPositionAttribute = [yuvConversionProgram attributeIndex:@"position"];
                yuvConversionTextureCoordinateAttribute = [yuvConversionProgram attributeIndex:@"inputTextureCoordinate"];
                yuvConversionLuminanceTextureUniform = [yuvConversionProgram uniformIndex:@"luminanceTexture"];
                yuvConversionChrominanceTextureUniform = [yuvConversionProgram uniformIndex:@"chrominanceTexture"];
                yuvConversionMatrixUniform = [yuvConversionProgram uniformIndex:@"colorConversionMatrix"];
                
                [GPUImageContext setActiveShaderProgram:yuvConversionProgram];
                
                glEnableVertexAttribArray(yuvConversionPositionAttribute);
                glEnableVertexAttribArray(yuvConversionTextureCoordinateAttribute);
            }
            
            if ([GPUImageContext supportsFastTextureUpload])
            {
                [GPUImageContext useImageProcessingContext];
#if defined(__IPHONE_6_0)
                CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [[GPUImageContext sharedImageProcessingContext] context], NULL, &coreVideoTextureCache);
#else
                CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (__bridge void *)[[GPUImageContext sharedImageProcessingContext] context], NULL, &coreVideoTextureCache);
#endif
                if (err)
                {
                    NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreate %d", err);
                }
                
                // Need to remove the initially created texture
                //            [self deleteOutputTexture];
            }
            else
            {
                [self initializeOutputTextureIfNeeded];
            }
        });
    }
    return self;
}

- (void)dealloc
{
    if ([GPUImageContext supportsFastTextureUpload])
    {
        CFRelease(coreVideoTextureCache);
    }
    
    // ARC forbids explicit message send of 'release'; since iOS 6 even for dispatch_release() calls: stripping it out in that case is required.
#if ( (__IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0) || (!defined(__IPHONE_6_0)) )
    if (frameRenderingSemaphore != NULL)
    {
        dispatch_release(frameRenderingSemaphore);
    }
#endif
    
//    if (captureAsYUV && [GPUImageContext deviceSupportsRedTextures])
    if (captureAsYUV && [GPUImageContext supportsFastTextureUpload])
    {
        [self destroyYUVConversionFBO];
    }
}

- (void)updateTargetsForVideoCameraUsingCacheTextureAtWidth:(int)bufferWidth height:(int)bufferHeight time:(CMTime)currentTime;
{
    for (id<GPUImageInput> currentTarget in targets)
    {
        if ([currentTarget enabled])
        {
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
            NSInteger textureIndexOfTarget = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
            
            if (currentTarget != self.targetToIgnoreForUpdates)
            {
                [currentTarget setInputRotation:outputRotation atIndex:textureIndexOfTarget];
                [currentTarget setInputSize:CGSizeMake(bufferWidth, bufferHeight) atIndex:textureIndexOfTarget];
                
                if ([currentTarget wantsMonochromeInput] && captureAsYUV)
                {
                    [currentTarget setCurrentlyReceivingMonochromeInput:YES];
                    [currentTarget setInputTexture:luminanceTexture atIndex:textureIndexOfTarget];
                }
                else
                {
                    [currentTarget setCurrentlyReceivingMonochromeInput:NO];
                    [currentTarget setInputTexture:outputTexture atIndex:textureIndexOfTarget];
                }
                
                [currentTarget newFrameReadyAtTime:currentTime atIndex:textureIndexOfTarget];
            }
            else
            {
                [currentTarget setInputRotation:outputRotation atIndex:textureIndexOfTarget];
                [currentTarget setInputTexture:outputTexture atIndex:textureIndexOfTarget];
            }
        }
    }
}

- (void)processVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer;
{
    CVImageBufferRef cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
	CMTime currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    [self processPixelBuffer:cameraFrame atTime:currentTime];
}

- (void)processPixelBuffer:(CVPixelBufferRef)cameraFrame
                    atTime:(CMTime)currentTime
{
    if (capturePaused)
    {
        return;
    }
    
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    int bufferWidth = (int) CVPixelBufferGetWidth(cameraFrame);
    int bufferHeight = (int) CVPixelBufferGetHeight(cameraFrame);
    CFTypeRef colorAttachments = CVBufferGetAttachment(cameraFrame, kCVImageBufferYCbCrMatrixKey, NULL);
    if (colorAttachments == kCVImageBufferYCbCrMatrix_ITU_R_601_4) {
        _preferredConversion = kColorConversion601;
    }
    else {
        _preferredConversion = kColorConversion709;
    }
    
    
    [GPUImageContext useImageProcessingContext];
    
    if ([GPUImageContext supportsFastTextureUpload])
    {
        CVOpenGLESTextureRef luminanceTextureRef = NULL;
        CVOpenGLESTextureRef chrominanceTextureRef = NULL;
        CVOpenGLESTextureRef texture = NULL;
        
        //        if (captureAsYUV && [GPUImageContext deviceSupportsRedTextures])
        if (CVPixelBufferGetPlaneCount(cameraFrame) > 0) // Check for YUV planar inputs to do RGB conversion
        {
            
            if ( (imageBufferWidth != bufferWidth) && (imageBufferHeight != bufferHeight) )
            {
                imageBufferWidth = bufferWidth;
                imageBufferHeight = bufferHeight;
                
                [self destroyYUVConversionFBO];
                [self createYUVConversionFBO];
            }
            
            CVReturn err;
            // Y-plane
            glActiveTexture(GL_TEXTURE4);
            if ([GPUImageContext deviceSupportsRedTextures])
            {
                //                err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, coreVideoTextureCache, cameraFrame, NULL, GL_TEXTURE_2D, GL_RED_EXT, bufferWidth, bufferHeight, GL_RED_EXT, GL_UNSIGNED_BYTE, 0, &luminanceTextureRef);
                err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, coreVideoTextureCache, cameraFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE, bufferWidth, bufferHeight, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0, &luminanceTextureRef);
            }
            else
            {
                err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, coreVideoTextureCache, cameraFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE, bufferWidth, bufferHeight, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0, &luminanceTextureRef);
            }
            if (err)
            {
                NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
            }
            
            luminanceTexture = CVOpenGLESTextureGetName(luminanceTextureRef);
            glBindTexture(GL_TEXTURE_2D, luminanceTexture);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            // UV-plane
            glActiveTexture(GL_TEXTURE5);
            if ([GPUImageContext deviceSupportsRedTextures])
            {
                //                err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, coreVideoTextureCache, cameraFrame, NULL, GL_TEXTURE_2D, GL_RG_EXT, bufferWidth/2, bufferHeight/2, GL_RG_EXT, GL_UNSIGNED_BYTE, 1, &chrominanceTextureRef);
                err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, coreVideoTextureCache, cameraFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE_ALPHA, bufferWidth/2, bufferHeight/2, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, 1, &chrominanceTextureRef);
            }
            else
            {
                err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, coreVideoTextureCache, cameraFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE_ALPHA, bufferWidth/2, bufferHeight/2, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, 1, &chrominanceTextureRef);
            }
            if (err)
            {
                NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
            }
            
            chrominanceTexture = CVOpenGLESTextureGetName(chrominanceTextureRef);
            glBindTexture(GL_TEXTURE_2D, chrominanceTexture);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            if (!allTargetsWantMonochromeData)
            {
                [self convertYUVToRGBOutput];
            }
            
            [self updateTargetsForVideoCameraUsingCacheTextureAtWidth:bufferWidth height:bufferHeight time:currentTime];
            
            CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
            CVOpenGLESTextureCacheFlush(coreVideoTextureCache, 0);
            CFRelease(luminanceTextureRef);
            CFRelease(chrominanceTextureRef);
        }
        else
        {
            CVPixelBufferLockBaseAddress(cameraFrame, 0);
            
            CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, coreVideoTextureCache, cameraFrame, NULL, GL_TEXTURE_2D, GL_RGBA, bufferWidth, bufferHeight, GL_BGRA, GL_UNSIGNED_BYTE, 0, &texture);
            
            if (!texture || err) {
                NSLog(@"Camera CVOpenGLESTextureCacheCreateTextureFromImage failed (error: %d)", err);
                NSAssert(NO, @"Camera failure");
                return;
            }
            
            outputTexture = CVOpenGLESTextureGetName(texture);
            //        glBindTexture(CVOpenGLESTextureGetTarget(texture), outputTexture);
            glBindTexture(GL_TEXTURE_2D, outputTexture);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            [self updateTargetsForVideoCameraUsingCacheTextureAtWidth:bufferWidth height:bufferHeight time:currentTime];
            
            CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
            CVOpenGLESTextureCacheFlush(coreVideoTextureCache, 0);
            CFRelease(texture);
            
            outputTexture = 0;
        }
        
        
        if (_runBenchmark)
        {
            numberOfFramesCaptured++;
            if (numberOfFramesCaptured > INITIALFRAMESTOIGNOREFORBENCHMARK)
            {
                CFAbsoluteTime currentFrameTime = (CFAbsoluteTimeGetCurrent() - startTime);
                totalFrameTimeDuringCapture += currentFrameTime;
                NSLog(@"Average frame time : %f ms", [self averageFrameDurationDuringCapture]);
                NSLog(@"Current frame time : %f ms", 1000.0 * currentFrameTime);
            }
        }
    }
    else
    {
        CVPixelBufferLockBaseAddress(cameraFrame, 0);
        
        glBindTexture(GL_TEXTURE_2D, outputTexture);
        
        //        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, bufferWidth, bufferHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(cameraFrame));
        
        // Using BGRA extension to pull in video frame data directly
        // The use of bytesPerRow / 4 accounts for a display glitch present in preview video frames when using the photo preset on the camera
        int bytesPerRow = (int) CVPixelBufferGetBytesPerRow(cameraFrame);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, bytesPerRow / 4, bufferHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(cameraFrame));
        
        for (id<GPUImageInput> currentTarget in targets)
        {
            if ([currentTarget enabled])
            {
                if (currentTarget != self.targetToIgnoreForUpdates)
                {
                    NSInteger indexOfObject = [targets indexOfObject:currentTarget];
                    NSInteger textureIndexOfTarget = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
                    
                    [currentTarget setInputSize:CGSizeMake(bufferWidth, bufferHeight) atIndex:textureIndexOfTarget];
                    [currentTarget newFrameReadyAtTime:currentTime atIndex:textureIndexOfTarget];
                }
            }
        }
        
        CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
        
        if (_runBenchmark)
        {
            numberOfFramesCaptured++;
            if (numberOfFramesCaptured > INITIALFRAMESTOIGNOREFORBENCHMARK)
            {
                CFAbsoluteTime currentFrameTime = (CFAbsoluteTimeGetCurrent() - startTime);
                totalFrameTimeDuringCapture += currentFrameTime;
            }
        }
    }  
}

- (void)convertYUVToRGBOutput;
{
    [GPUImageContext setActiveShaderProgram:yuvConversionProgram];
    [self setYUVConversionFBO];
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    static const GLfloat textureCoordinates[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
    };
    
	glActiveTexture(GL_TEXTURE4);
	glBindTexture(GL_TEXTURE_2D, luminanceTexture);
	glUniform1i(yuvConversionLuminanceTextureUniform, 4);
    
    glActiveTexture(GL_TEXTURE5);
	glBindTexture(GL_TEXTURE_2D, chrominanceTexture);
	glUniform1i(yuvConversionChrominanceTextureUniform, 5);
    
    glUniformMatrix3fv(yuvConversionMatrixUniform, 1, GL_FALSE, _preferredConversion);
    
    glVertexAttribPointer(yuvConversionPositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
	glVertexAttribPointer(yuvConversionTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

- (void)setYUVConversionFBO;
{
    if (!yuvConversionFramebuffer)
    {
        [self createYUVConversionFBO];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, yuvConversionFramebuffer);
    
    glViewport(0, 0, imageBufferWidth, imageBufferHeight);
}

- (void)createYUVConversionFBO;
{
    [self initializeOutputTextureIfNeeded];
    
    glActiveTexture(GL_TEXTURE1);
    glGenFramebuffers(1, &yuvConversionFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, yuvConversionFramebuffer);
    
    glBindTexture(GL_TEXTURE_2D, outputTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imageBufferWidth, imageBufferHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, outputTexture, 0);
    
	GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    [self notifyTargetsAboutNewOutputTexture];
    
    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
    glBindTexture(GL_TEXTURE_2D, 0);
    
}

- (void)destroyYUVConversionFBO;
{
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];
        
        if (yuvConversionFramebuffer)
        {
            glDeleteFramebuffers(1, &yuvConversionFramebuffer);
            yuvConversionFramebuffer = 0;
        }
        
        if (outputTexture)
        {
            glDeleteTextures(1, &outputTexture);
            outputTexture = 0;
        }
    });
}

#pragma mark -
#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (dispatch_semaphore_wait(frameRenderingSemaphore, DISPATCH_TIME_NOW) != 0)
    {
        return;
    }
    
    CFRetain(sampleBuffer);
    runAsynchronouslyOnVideoProcessingQueue(^{
        //Feature Detection Hook.
        if (self.delegate)
        {
            [self.delegate willOutputSampleBuffer:sampleBuffer];
        }
        
        [self processVideoSampleBuffer:sampleBuffer];
        
        CFRelease(sampleBuffer);
        dispatch_semaphore_signal(frameRenderingSemaphore);
    });
}

- (BOOL)capturePixelBuffer:(CVPixelBufferRef)pixelBuffer atTime:(CMTime)time
{
    if (dispatch_semaphore_wait(frameRenderingSemaphore, DISPATCH_TIME_NOW) != 0)
    {
        return NO;
    }
    
    CFRetain(pixelBuffer);
    runAsynchronouslyOnVideoProcessingQueue(^{
        [self processPixelBuffer:pixelBuffer atTime:time];
        
        CFRelease(pixelBuffer);
        dispatch_semaphore_signal(frameRenderingSemaphore);
    });
    
    return YES;
}

#pragma mark -
#pragma mark Managing targets

- (void)addTarget:(id<GPUImageInput>)newTarget atTextureLocation:(NSInteger)textureLocation;
{
    [super addTarget:newTarget atTextureLocation:textureLocation];
    
    [newTarget setInputRotation:outputRotation atIndex:textureLocation];
}

#pragma mark -
#pragma mark Benchmarking

- (CGFloat)averageFrameDurationDuringCapture;
{
    return (totalFrameTimeDuringCapture / (CGFloat)(numberOfFramesCaptured - INITIALFRAMESTOIGNOREFORBENCHMARK)) * 1000.0;
}

- (void)resetBenchmarkAverage;
{
    numberOfFramesCaptured = 0;
    totalFrameTimeDuringCapture = 0.0;
}

#pragma mark -
#pragma mark Accessors

- (void)setOutputRotation:(GPUImageRotationMode)anOutputRotation
{
    runSynchronouslyOnVideoProcessingQueue(^{
        outputRotation = anOutputRotation;
        
        for (id<GPUImageInput> currentTarget in targets)
        {
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
            [currentTarget setInputRotation:outputRotation atIndex:[[targetTextureIndices objectAtIndex:indexOfObject] integerValue]];
        }
    });
}

+ (GPUImageRotationMode)rotationForImageOrientation:(UIInterfaceOrientation)imageOrientation
                                    captureDevicePosition:(AVCaptureDevicePosition)position
                                    horizontallyMirrored:(BOOL)horizontallyMirrored
{
    if (position == AVCaptureDevicePositionBack)
    {
        if (horizontallyMirrored)
        {
            switch(imageOrientation)
            {
                case UIInterfaceOrientationPortrait:return kGPUImageRotateRightFlipVertical; break;
                case UIInterfaceOrientationPortraitUpsideDown:return kGPUImageRotate180; break;
                case UIInterfaceOrientationLandscapeLeft:return kGPUImageFlipHorizonal; break;
                case UIInterfaceOrientationLandscapeRight:return kGPUImageFlipVertical; break;
            }
        }
        else
        {
            switch(imageOrientation)
            {
                case UIInterfaceOrientationPortrait:return kGPUImageRotateRight; break;
                case UIInterfaceOrientationPortraitUpsideDown:return kGPUImageRotateLeft; break;
                case UIInterfaceOrientationLandscapeLeft:return kGPUImageRotate180; break;
                case UIInterfaceOrientationLandscapeRight:return kGPUImageNoRotation; break;
            }
        }
    }
    else
    {
        if (horizontallyMirrored)
        {
            switch(imageOrientation)
            {
                case UIInterfaceOrientationPortrait:return kGPUImageRotateRightFlipVertical; break;
                case UIInterfaceOrientationPortraitUpsideDown:return kGPUImageRotateRightFlipHorizontal; break;
                case UIInterfaceOrientationLandscapeLeft:return kGPUImageFlipHorizonal; break;
                case UIInterfaceOrientationLandscapeRight:return kGPUImageFlipVertical; break;
            }
        }
        else
        {
            switch(imageOrientation)
            {
                case UIInterfaceOrientationPortrait:return kGPUImageRotateRight; break;
                case UIInterfaceOrientationPortraitUpsideDown:return kGPUImageRotateLeft; break;
                case UIInterfaceOrientationLandscapeLeft:return kGPUImageNoRotation; break;
                case UIInterfaceOrientationLandscapeRight:return kGPUImageRotate180; break;
            }
        }
    }
}

@end

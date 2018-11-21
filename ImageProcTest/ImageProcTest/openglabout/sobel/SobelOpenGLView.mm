//
//  OpenGLView.m
//  Tutorial01
//
//  Created by kesalin@gmail.com on 12-11-24.
//  Copyright (c) 2012年 http://blog.csdn.net/kesalin/. All rights reserved.
//

#import "SobelOpenGLView.h"
#import "GLESUtils.h"

// 使用匿名 category 来声明私有成员
@interface SobelOpenGLView()
{
    GLuint framebufferColorTexture;
}

- (void)setupLayer;
- (void)setupContext;
- (void)setupProgram;

- (void)setupBuffers;
- (void)destoryBuffers;

@end

@implementation SobelOpenGLView

+ (Class)layerClass {
    // 只有 [CAEAGLLayer class] 类型的 layer 才支持在其上描绘 OpenGL 内容。
    return [CAEAGLLayer class];
}

- (void)setupLayer
{
    _eaglLayer = (CAEAGLLayer*) self.layer;
    
    // CALayer 默认是透明的，必须将它设为不透明才能让其可见
    _eaglLayer.opaque = YES;
    
    // 设置描绘属性，在这里设置不维持渲染内容以及颜色格式为 RGBA8
    _eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
}

- (void)setupContext {
    // 指定 OpenGL 渲染 API 的版本，在这里我们使用 OpenGL ES 2.0
    
#if 0
    
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    _context = [[EAGLContext alloc] initWithAPI:api sharegroup:[fImgEng getEAGLContext].sharegroup];
    if (!_context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    
#else
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    _context = [[EAGLContext alloc] initWithAPI:api];
    if (!_context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
#endif
    // 设置为当前上下文
    if (![EAGLContext setCurrentContext:_context]) {
        _context = nil;
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
}

- (void)setupBuffers
{
    glGenRenderbuffers(1, &_colorRenderBuffer);
    // 设置为当前 renderbuffer
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    // 为 color renderbuffer 分配存储空间
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
    
    glGenFramebuffers(1, &_frameBuffer);
    // 设置为当前 framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    // 将 _colorRenderBuffer 装配到 GL_COLOR_ATTACHMENT0 这个装配点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, _colorRenderBuffer);
    
    glGenFramebuffers(1, &_frameBufferTex);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBufferTex);
    glGenTextures(1, &framebufferColorTexture);
//    glActiveTexture(GL_TEXTURE13);
    glBindTexture(GL_TEXTURE_2D, framebufferColorTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 480, 640, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, framebufferColorTexture, 0);
}

- (void)destoryBuffers
{
    glDeleteRenderbuffers(1, &_colorRenderBuffer);
    _colorRenderBuffer = 0;
    
    glDeleteFramebuffers(1, &_frameBuffer);
    _frameBuffer = 0;
}

- (void)setupProgram
{
    // Load shaders
    //
    NSString * vertexShaderPath = [[NSBundle mainBundle] pathForResource:@"SobelVertexShader"
                                                                  ofType:@"glsl"];
    NSString * fragmentShaderPath = [[NSBundle mainBundle] pathForResource:@"SobelFragmentShader"
                                                                    ofType:@"glsl"];
    
    // Create program, attach shaders, compile and link program
    //
    _programHandle = [GLESUtils loadProgram:vertexShaderPath
                 withFragmentShaderFilepath:fragmentShaderPath];
    if (_programHandle == 0) {
        NSLog(@" >> Error: Failed to setup program.");
        return;
    }

    NSString * vertexShaderPath2 = [[NSBundle mainBundle] pathForResource:@"SobelVertexShader2"
                                                                  ofType:@"glsl"];
    NSString * fragmentShaderPath2 = [[NSBundle mainBundle] pathForResource:@"SobelFragmentShader2"
                                                                    ofType:@"glsl"];

    _programHandle2 = [GLESUtils loadProgram:vertexShaderPath2
                 withFragmentShaderFilepath:fragmentShaderPath2];
    if (_programHandle2 == 0) {
        NSLog(@" >> Error: Failed to setup program.");
        return;
    }

    glUseProgram(_programHandle);
    
    // Get attribute slot from program
    //
    _positionSlot = glGetAttribLocation(_programHandle, "position");
    _texCoordSlot = glGetAttribLocation(_programHandle, "texCoord");
    
    if (_textureCache == nil) {
        CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, nil, _context, nil, &_textureCache);
    }
    
}

- (void)render:(CVPixelBufferRef)pixbuffer
{
    NSLog(@"render\n");
    
    glUseProgram(_programHandle);
    [EAGLContext setCurrentContext:_context];
    
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBufferTex);
    
    [self loadTexture:pixbuffer];
    
    glClearColor(0, 1.0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // Setup viewport
    //
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    GLfloat vertices[] = {
        -1,-1,-1,-1,
        1,-1,-1,-1,
        -1,1,-1,-1,
        1,1,-1,-1,
    };
    
    GLfloat texturePoints[] = {
        1,1,
        1,0,
        0,1,
        0,0,
    };
    
    glVertexAttribPointer(_positionSlot, 2, GL_FLOAT, GL_FALSE, 4*sizeof(GLfloat), vertices);
    glEnableVertexAttribArray(_positionSlot);
    
    glVertexAttribPointer(_texCoordSlot, 2, GL_FLOAT, GL_FALSE, 2*sizeof(GLfloat),  texturePoints);
    glEnableVertexAttribArray(_texCoordSlot);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    CFRelease(_imgTexture);
    _imgTexture = nil;
    [_context presentRenderbuffer:GL_RENDERBUFFER];
    
    /////////
    glUseProgram(_programHandle2);
    [EAGLContext setCurrentContext:_context];
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glBindTexture(GL_TEXTURE_2D, framebufferColorTexture);
    glClearColor(0, 1.0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // Setup viewport
    //
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupLayer];
        [self setupContext];
        [self setupProgram];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [EAGLContext setCurrentContext:_context];
    
    [self destoryBuffers];
    
    [self setupBuffers];
    
    //    [self render];
}

- (void)loadTexture:(CVPixelBufferRef)pixelBuffer
{
    size_t frameWidth = CVPixelBufferGetWidth(pixelBuffer);
    size_t frameHeight = CVPixelBufferGetHeight(pixelBuffer);
    OSType type = CVPixelBufferGetPixelFormatType(pixelBuffer);
    
    CVReturn err  = 0;
    glActiveTexture(GLenum(GL_TEXTURE0));
    CVOpenGLESTextureCacheFlush(_textureCache, 0);
    if (_imgTexture != nil) {
        CFRelease(_imgTexture);
        _imgTexture = nil;
    }
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       _textureCache,
                                                       pixelBuffer,
                                                       nil,
                                                       GLenum(GL_TEXTURE_2D),
                                                       GL_RGBA,
                                                       GLsizei(frameWidth),
                                                       GLsizei(frameHeight),
                                                       GLenum(GL_RGBA),
                                                       GLenum(GL_UNSIGNED_BYTE),
                                                       0,
                                                       &_imgTexture);
    if (err != kCVReturnSuccess) {
        return;
    }
    
    glBindTexture(CVOpenGLESTextureGetTarget(_imgTexture), CVOpenGLESTextureGetName(_imgTexture));
    glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR);
    glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR);
    glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GLfloat(GL_CLAMP_TO_EDGE));
    glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GLfloat(GL_CLAMP_TO_EDGE));
}


/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */


@end

//
//  OpenGLView.m
//  Tutorial01
//
//  Created by kesalin@gmail.com on 12-11-24.
//  Copyright (c) 2012年 http://blog.csdn.net/kesalin/. All rights reserved.
//

#import "MaskOpenGLView.h"
#import "GLESUtils.h"
#import "ImageTools.h"

// 使用匿名 category 来声明私有成员
@interface MaskOpenGLView()
{
    
}

- (void)setupLayer;
- (void)setupContext;
- (void)setupProgram;

- (void)setupBuffers;
- (void)destoryBuffers;

@end

@implementation MaskOpenGLView

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
    NSString * vertexShaderPath = [[NSBundle mainBundle] pathForResource:@"MaskVertexShader"
                                                                  ofType:@"glsl"];
    NSString * fragmentShaderPath = [[NSBundle mainBundle] pathForResource:@"MaskFragmentShader"
                                                                    ofType:@"glsl"];
    
    // Create program, attach shaders, compile and link program
    //
    _programHandle = [GLESUtils loadProgram:vertexShaderPath
                 withFragmentShaderFilepath:fragmentShaderPath];
    if (_programHandle == 0) {
        NSLog(@" >> Error: Failed to setup program.");
        return;
    }

    glUseProgram(_programHandle);
    
    // Get attribute slot from program
    //
    _positionSlot = glGetAttribLocation(_programHandle, "position");
    _texCoordSlot = glGetAttribLocation(_programHandle, "texCoord");
    _texCoordSlot2 = glGetAttribLocation(_programHandle, "texCoord2");

    if (_textureCache == nil) {
        CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, nil, _context, nil, &_textureCache);
    }

    GLint textureId;
    textureId = glGetUniformLocation(_programHandle, "SamplerRGBA1");
    glUniform1i(textureId, 2);
    textureId = glGetUniformLocation(_programHandle, "SamplerRGBA2");
    glUniform1i(textureId, 17);

    UIImage *image = [UIImage imageNamed:@"mask.png"];
    [self setupTexture:image];

}

- (void)render:(CVPixelBufferRef)pixbuffer
{
    NSLog(@"render\n");
    
    [EAGLContext setCurrentContext:_context];
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    
    [self loadTexture1:pixbuffer];
//    [self loadTexture2:pixbuffer];
    
    glClearColor(0, 1.0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // Setup viewport
    //
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    GLfloat vertices[] = {
        -1,-1,
        1,-1,
        -1,1,
        1,1,
    };
    
    GLfloat texturePoints[] = {
        1,1,
        1,0,
        0,1,
        0,0,
    };
    
    glVertexAttribPointer(_positionSlot, 2, GL_FLOAT, GL_FALSE, 2*sizeof(GLfloat), vertices);
    glEnableVertexAttribArray(_positionSlot);
    glVertexAttribPointer(_texCoordSlot, 2, GL_FLOAT, GL_FALSE, 2*sizeof(GLfloat),  texturePoints);
    glEnableVertexAttribArray(_texCoordSlot);
    
    GLfloat texturePoints2[] = {
        1,1,
        1,0,
        0,1,
        0,0,
    };

    glVertexAttribPointer(_texCoordSlot2, 2, GL_FLOAT, GL_FALSE, 2*sizeof(GLfloat),  texturePoints2);
    glEnableVertexAttribArray(_texCoordSlot2);

    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glDisable(GL_BLEND);
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

- (void)loadTexture1:(CVPixelBufferRef)pixelBuffer
{
    size_t frameWidth = CVPixelBufferGetWidth(pixelBuffer);
    size_t frameHeight = CVPixelBufferGetHeight(pixelBuffer);
    OSType type = CVPixelBufferGetPixelFormatType(pixelBuffer);
    
    CVReturn err  = 0;
    glActiveTexture(GLenum(GL_TEXTURE2));
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

- (void)loadTexture2:(CVPixelBufferRef)pixelBuffer
{
//    UIImage *image = [UIImage imageNamed:@"xyjy2.jpg"];
//    ImageTools *tool = [[ImageTools alloc] init];
//    CVPixelBufferRef pixelBuffer = [tool pixelBufferFromCGImage:[image CGImage]];

//    size_t frameWidth = CVPixelBufferGetWidth(pixelBuffer);
//    size_t frameHeight = CVPixelBufferGetHeight(pixelBuffer);
//    OSType type = CVPixelBufferGetPixelFormatType(pixelBuffer);
//
//    CVReturn err  = 0;
//    glActiveTexture(GLenum(GL_TEXTURE1));
//    CVOpenGLESTextureCacheFlush(_textureCache, 0);
//    if (_imgTexture2 != nil) {
//        CFRelease(_imgTexture2);
//        _imgTexture2 = nil;
//    }
//    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
//                                                       _textureCache,
//                                                       pixelBuffer,
//                                                       nil,
//                                                       GLenum(GL_TEXTURE_2D),
//                                                       GL_RGBA,
//                                                       GLsizei(frameWidth),
//                                                       GLsizei(frameHeight),
//                                                       GLenum(GL_RGBA),
//                                                       GLenum(GL_UNSIGNED_BYTE),
//                                                       0,
//                                                       &_imgTexture2);
//    if (err != kCVReturnSuccess) {
//        return;
//    }
//
//    glBindTexture(CVOpenGLESTextureGetTarget(_imgTexture2), CVOpenGLESTextureGetName(_imgTexture2));
//    glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR);
//    glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR);
//    glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GLfloat(GL_CLAMP_TO_EDGE));
//    glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GLfloat(GL_CLAMP_TO_EDGE));
}

    /**
     *  加载image, 使用CoreGraphics将位图以RGBA格式存放. 将UIImage图像数据转化成OpenGL ES接受的数据.
     *  然后在GPU中将图像纹理传递给GL_TEXTURE_2D。
     *  @return 返回的是纹理对象，该纹理对象暂时未跟GL_TEXTURE_2D绑定（要调用bind）。
     *  即GL_TEXTURE_2D中的图像数据都可从纹理对象中取出。
     */
- (GLuint)setupTexture:(UIImage *)image {
    CGImageRef cgImageRef = [image CGImage];
    GLuint width = (GLuint)CGImageGetWidth(cgImageRef);
    GLuint height = (GLuint)CGImageGetHeight(cgImageRef);
    CGRect rect = CGRectMake(0, 0, width, height);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    void *imageData = malloc(width * height * 4);
    CGContextRef context = CGBitmapContextCreate(imageData, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1.0f, -1.0f);
    CGColorSpaceRelease(colorSpace);
    CGContextClearRect(context, rect);
    CGContextDrawImage(context, rect, cgImageRef);
    
    glEnable(GL_TEXTURE_2D);
    
    /**
     *  GL_TEXTURE_2D表示操作2D纹理
     *  创建纹理对象，
     *  绑定纹理对象，
     */
    
    GLuint textureID;
    glGenTextures(1, &textureID);
    glActiveTexture(GLenum(GL_TEXTURE17));
    for(GLenum err; (err = glGetError()) != GL_NO_ERROR;)
    {
        printf("err:%d\n", err);
    }
    glBindTexture(GL_TEXTURE_2D, textureID);
    
    /**
     *  纹理过滤函数
     *  图象从纹理图象空间映射到帧缓冲图象空间(映射需要重新构造纹理图像,这样就会造成应用到多边形上的图像失真),
     *  这时就可用glTexParmeteri()函数来确定如何把纹理象素映射成像素.
     *  如何把图像从纹理图像空间映射到帧缓冲图像空间（即如何把纹理像素映射成像素）
     */
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE); // S方向上的贴图模式
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE); // T方向上的贴图模式
    // 线性过滤：使用距离当前渲染像素中心最近的4个纹理像素加权平均值
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    /**
     *  将图像数据传递给到GL_TEXTURE_2D中, 因其于textureID纹理对象已经绑定，所以即传递给了textureID纹理对象中。
     *  glTexImage2d会将图像数据从CPU内存通过PCIE上传到GPU内存。
     *  不使用PBO时它是一个阻塞CPU的函数，数据量大会卡。
     */
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    
    // 结束后要做清理
    CGContextRelease(context);
    free(imageData);
    
    return textureID;
}

@end

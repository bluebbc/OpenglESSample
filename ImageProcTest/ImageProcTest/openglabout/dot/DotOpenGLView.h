//
//  DotOpenGLView.h
//  Tutorial01
//
//  Created by kesalin@gmail.com on 12-11-24.
//  Copyright (c) 2012年 http://blog.csdn.net/kesalin/. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

@interface DotOpenGLView : UIView {
    CAEAGLLayer* _eaglLayer;
    EAGLContext* _context;
    GLuint _colorRenderBuffer;
    GLuint _frameBuffer;
    
    GLuint _programHandle;
    GLuint _positionSlot;
    GLuint _texCoordSlot;
    GLuint _texCoordSlot2;
    
    GLint _textureId;
    GLint _textureId2;
    
    CVOpenGLESTextureCacheRef _textureCache;
    CVOpenGLESTextureRef _imgTexture;
    CVOpenGLESTextureRef _imgTexture2;
}

- (void)render:(CVPixelBufferRef)pixbuffer;

@end

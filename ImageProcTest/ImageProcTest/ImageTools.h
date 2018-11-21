//
//  ImageTools.h
//  ImageEngineSample
//
//  Created by maozheng on 2018/5/5.
//  Copyright © 2018年 maozheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ImageTools : NSObject

- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image;

@end

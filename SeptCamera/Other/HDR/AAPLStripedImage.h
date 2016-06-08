/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
         Implements a composite image constructed of CMSampleBuffer stripes.
 
  由CMSampleBuffer条纹组成一个混合图像
     
 */

@import CoreMedia;

@interface AAPLStripedImage : NSObject

// Designated initializer  指定初始化
- (instancetype)initForSize:(CGSize)size stripWidth:(CGFloat)stripWidth stride:(NSUInteger)stride;

// Add an image to the strip   把图像添加到条纹
// sampleBuffer must be a JPEG or BGRA image
- (void)addSampleBuffer:(CMSampleBufferRef)sampleBuffer;

// The final rendered strip  最后合成图片
- (UIImage *)imageWithOrientation:(UIImageOrientation)orientation;

@end

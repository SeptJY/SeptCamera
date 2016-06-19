//
//  JYVideoCamera.h
//  TestVideo
//
//  Created by Sept on 16/5/26.
//  Copyright © 2016年 九月. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPUImage.h"

@protocol JYVideoCameraDelegate <NSObject>

@optional
- (void)cameraManagerRecodingSuccess:(NSURL *)url;

- (void)cameraManageTakingPhotoSucuess:(UIImage *)image;

- (void)cameraManageTakingPhotoSucuessArray:(NSMutableArray *)images;

- (void)videoCameraDidOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end

@interface JYVideoCamera : NSObject
{
    GPUImageMovieWriter *movieWriter;
}

@property (copy, nonatomic) NSString *pathToMovie;

@property (weak, nonatomic) id<JYVideoCameraDelegate> delegate;

@property (strong, nonatomic) GPUImageView *scaleView;

typedef void(^CanSetSessionPreset)(BOOL isCan);

@property (strong, nonatomic) GPUImageStillCamera *videoCamera;

@property (copy, nonatomic) NSString *sessionPreset;

@property (nonatomic, strong) GPUImageExposureFilter *exposureFilter;
@property (nonatomic, strong) GPUImageSaturationFilter *saturationFilter;

@property (strong, nonatomic) GPUImageLowPassFilter *lowPassFilter;
@property (strong, nonatomic) GPUImageFilterGroup *filter;

- (instancetype)initWithSessionPreset:(NSString *)sessionPreset superView:(UIView *)superView;

@property (nonatomic, copy) void (^onBuffer)(CMSampleBufferRef sampleBuffer);
@property (nonatomic, assign) BOOL isRecording;

@property (assign, nonatomic) CGSize videoSize;

@property (assign, nonatomic) int32_t frameRate;

- (void)startVideo;
- (void)stopVideo;

- (void)startCamera;
- (void)stopCamera;

- (void)cameraManagerChangeFoucus:(CGFloat)value;

- (void)videoCameraWithExposureTime:(CGFloat)time andIso:(CGFloat)iso;

- (void)cameraManagerEffectqualityWithTag:(NSInteger)tag withBlock:(CanSetSessionPreset)canSetSessionPreset;

@property (assign, nonatomic) CGFloat quality;

- (void)flashModel:(AVCaptureFlashMode)flashModel;

- (void)cameraManagerVideoZoom:(CGFloat)zoom;

- (void)cameraManagerSetWhiteBalanceGains:(AVCaptureWhiteBalanceGains)gains;

- (AVCaptureWhiteBalanceGains)normalizedGains:(AVCaptureWhiteBalanceGains) gains;

- (void)whiteBalanceMode:(AVCaptureWhiteBalanceMode)whiteBalanceMode;

- (void)cameraManagerBalanceGainsWithTemp:(CGFloat)temp andTint:(CGFloat)tint;

- (void)cameraManagerExposureIOS:(CGFloat)iso;

- (void)setExposureDurationWith:(CGFloat)value;

- (void)exposeMode:(AVCaptureExposureMode)exposureMode;

- (void)resetFormat;

- (void)switchFormatWithDesiredFPS:(CGFloat)desiredFPS;

- (void)takePhoto;

- (void)takePhotosWithHDR;

- (void)prepareHDRWithIndex:(NSInteger)index;

- (void)takePhotoWithArray;

- (void)resetFormats;

- (void)aswitchFormatWithDesiredFPS:(CGFloat)desiredFPS;

@property (strong, nonatomic) NSMutableArray *imgsArray;

- (void)aaaaaaaaa;

- (void)bbbbbbbbbbb;

@end

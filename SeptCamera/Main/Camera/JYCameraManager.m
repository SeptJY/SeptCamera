//
//  JYCameraManager.m
//  Esaycamera
//
//  Created by Sept on 16/4/8.
//  Copyright © 2016年 九月. All rights reserved.
//

#import "JYCameraManager.h"

#import <Photos/Photos.h>


@interface JYCameraManager () <GPUImageMovieWriterDelegate>
{
    CGRect _frame;
    GPUImageMovieWriter *movieWriter;
    CMTime defaultVideoMaxFrameDuration;
}
@property (nonatomic, unsafe_unretained) dispatch_queue_t prepareFilterQueue;

@property (nonatomic , strong) GPUImageView *cameraScreen;

@property (nonatomic, strong) AVCaptureDeviceFormat *defaultFormat;

@end

@implementation JYCameraManager

- (instancetype)initWithFrame:(CGRect)frame superview:(UIView *)superview {
    
    self = [super init];
    if (self) {
        _frame = frame;
        [superview addSubview:self.cameraScreen];
        
        self.videoSize = CGSizeMake(1280.0, 720.0);
        
        self.defaultFormat = self.camera.inputCamera.activeFormat;
        defaultVideoMaxFrameDuration = self.camera.inputCamera.activeVideoMaxFrameDuration;
        
        
    }
    return self;
}

- (void)takePhoto
{
    [self.camera capturePhotoAsJPEGProcessedUpToFilter:self.filter withCompletionHandler:^(NSData *processedJPEG, NSError *error) {
        
        if (!error) {
//            [[JYSaveVideoData sharedManager] saveImageWithData:processedJPEG];
            [PHPhotoLibrary requestAuthorization:^( PHAuthorizationStatus status ) {
                if ( status == PHAuthorizationStatusAuthorized ) {
                    // To preserve the metadata, we create an asset from the JPEG NSData representation.
                    // 创建JPEG类型数据保存云数据
                    // In iOS 9, we can use -[PHAssetCreationRequest addResourceWithType:data:options].
                    // In iOS 8, we save the image to a temporary file and use +[PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:].
                    if ( [PHAssetCreationRequest class] ) {
                        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                            [[PHAssetCreationRequest creationRequestForAsset] addResourceWithType:PHAssetResourceTypePhoto data:processedJPEG options:nil];
                        } completionHandler:^( BOOL success, NSError *error ) {
                            if ( ! success ) {
                                // 保存图像到照片库时出错
                                NSLog( @"Error occurred while saving image to photo library: %@", error );
                            }
                        }];
                    }
                    else {
                        NSString *temporaryFileName = [NSProcessInfo processInfo].globallyUniqueString;
                        NSString *temporaryFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[temporaryFileName stringByAppendingPathExtension:@"jpg"]];
                        NSURL *temporaryFileURL = [NSURL fileURLWithPath:temporaryFilePath];
                        
                        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                            NSError *error = nil;
                            [processedJPEG writeToURL:temporaryFileURL options:NSDataWritingAtomic error:&error];
                            
                            if ( error ) {
                                // 将图像数据写入临时文件时出错
                                NSLog( @"Error occured while writing image data to a temporary file: %@", error );
                            }
                            else {
                                [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:temporaryFileURL];
                            }
                        } completionHandler:^( BOOL success, NSError *error ) {
                            
                            if ( ! success ) {
                                // 保存图像到照片库时出错
                                NSLog( @"Error occurred while saving image to photo library: %@", error );
                            }
                            
                            // 删除临时文件
                            [[NSFileManager defaultManager] removeItemAtURL:temporaryFileURL error:nil];
                        }];
                    }
                }
            }];
            // 返回拍照数据
            if (self.cameraDelegate && [self.cameraDelegate respondsToSelector:@selector(cameraManageTakingPhotoSucuess:)]) {
                [self.cameraDelegate cameraManageTakingPhotoSucuess:processedJPEG];
            }
        }else
        {
            NSLog(@"拍照时，error = %@", error);
        }
    }];
}

- (GPUImageView *)cameraScreen {
    if (!_cameraScreen) {
        GPUImageView *cameraScreen = [[GPUImageView alloc] initWithFrame:_frame];
        cameraScreen.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
        _cameraScreen = cameraScreen;
    }
    return _cameraScreen;
}

- (GPUImageView *)subPreview
{
    if (!_subPreview) {
        GPUImageView *subPreview = [[GPUImageView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
        subPreview.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
        subPreview.transform = CGAffineTransformMakeScale(4.0, 4.0);
        _subPreview = subPreview;
    }
    return _subPreview;
}

/**
 
 AVCaptureSessionPreset640x480
 AVCaptureSessionPresetHigh
 */

- (GPUImageStillCamera *)camera
{
    if (!_camera) {
        _camera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
        _camera.outputImageOrientation = UIInterfaceOrientationLandscapeRight;
        _camera.horizontallyMirrorFrontFacingCamera = NO;
        _camera.horizontallyMirrorRearFacingCamera = NO;
        
        self.filter = [[GPUImageSaturationFilter alloc] init];
        
        [_camera addTarget:self.filter];
        [self.filter addTarget:self.cameraScreen];
        [self.filter addTarget:self.subPreview];
    }
    return _camera;
}

#pragma mark 启用预览
- (void)startCamera{
    [self.camera startCameraCapture];
}

#pragma mark 关闭预览
- (void)stopCamera{
    [self.camera stopCameraCapture];
}

- (void)startVideo
{
    movieWriter = [self writer];
    [movieWriter startRecording];
}

- (void)stopVideo
{
    // 1.停止录像
    [self.filter removeTarget:movieWriter];
    self.camera.audioEncodingTarget = nil;
    [movieWriter finishRecording];
}

- (void)switchFormatWithDesiredFPS:(CGFloat)desiredFPS
{
    NSLog(@"ff %@", self.camera.inputCamera.activeFormat);
    BOOL isRunning = self.camera.captureSession.isRunning;
    
    if (isRunning)  [self.camera.captureSession stopRunning];
    
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceFormat *selectedFormat = nil;
    int32_t maxWidth = 0;
    AVFrameRateRange *frameRateRange = nil;
    
    for (AVCaptureDeviceFormat *format in [videoDevice formats]) {
        
        for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges) {
            
            CMFormatDescriptionRef desc = format.formatDescription;
            CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(desc);
            int32_t width = dimensions.width;
//            NSLog(@"1- %d, 2- %d, 3- %d", range.minFrameRate <= desiredFPS, desiredFPS <= range.maxFrameRate, width >= maxWidth);
//            NSLog(@"min - %f, max - %f", range.minFrameRate, range.maxFrameRate);
            if (range.minFrameRate <= desiredFPS && width == (int)self.videoSize.width) {
                
                selectedFormat = format;
                frameRateRange = range;
                maxWidth = width;
                NSLog(@"11 = 1- %f, 2- %f, 3- %d, %d", range.minFrameRate, range.maxFrameRate, width, maxWidth);
            } else {
                NSLog(@"22 = 1- %f, 2- %f, 3- %d, %d", range.minFrameRate, range.maxFrameRate, width, maxWidth);
            }
        }
    }
    
    if (selectedFormat) {
        
        if ([videoDevice lockForConfiguration:nil]) {
            
            CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(selectedFormat.formatDescription);
            self.videoSize = CGSizeMake(dimensions.width, dimensions.height);
//            NSLog(@"%@", selectedFormat.formatDescription);
            NSLog(@"selected format:h = %d -- w = %d", dimensions.height, dimensions.width);
            
            videoDevice.activeFormat = selectedFormat;
            videoDevice.activeVideoMinFrameDuration = CMTimeMake(1, (int32_t)desiredFPS);
            videoDevice.activeVideoMaxFrameDuration = CMTimeMake(1, (int32_t)desiredFPS);
            [videoDevice unlockForConfiguration];
            NSLog(@"TT %@", videoDevice.activeFormat);
        }
//        NSLog(@"cc %@", self.camera.captureSession.sessionPreset);
    }
    
    if (isRunning) [self.camera.captureSession startRunning];
}

- (void)resetFormat {
    
    BOOL isRunning = self.camera.captureSession.isRunning;
    
    if (isRunning) {
        [self.camera.captureSession stopRunning];
    }
    
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [videoDevice lockForConfiguration:nil];
    videoDevice.activeFormat = self.defaultFormat;
    videoDevice.activeVideoMaxFrameDuration = defaultVideoMaxFrameDuration;
    [videoDevice unlockForConfiguration];
    
    if (isRunning) {
        [self.camera.captureSession startRunning];
    }
}

- (GPUImageMovieWriter *)writer
{
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.MOV"];
    unlink([pathToMovie UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    
    GPUImageMovieWriter *writer = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:self.videoSize];
    writer.shouldPassthroughAudio = YES;
    writer.delegate = self;
    
    [self.filter addTarget:writer];
    self.camera.audioEncodingTarget = writer;
    
    return writer;
}

- (void)movieRecordingvideoSaveSuccess:(NSURL *)url
{
    if (self.cameraDelegate && [self.cameraDelegate respondsToSelector:@selector(cameraManagerRecodingSuccess:)]) {
        [self.cameraDelegate cameraManagerRecodingSuccess:url];
    }
}

#pragma mark -------------------------> 调焦焦距
- (void)cameraManagerChangeFoucus:(CGFloat)value
{
//    NSLog(@"%f", value);
    CGFloat lensPosition = value - 0.5;
    if (self.camera.inputCamera.position == AVCaptureDevicePositionBack) {
        if (lensPosition < 0) {
            lensPosition = 0;
        }
        
        if (lensPosition > 1) {
            lensPosition = 1;
        }
        
        NSError *error = nil;
        AVCaptureDevice *currentVideoDevice = self.camera.inputCamera;
        if ([currentVideoDevice lockForConfiguration:&error]) {
            
            [currentVideoDevice setAutoFocusRangeRestriction:AVCaptureAutoFocusRangeRestrictionNone];
            
            [currentVideoDevice setFocusModeLockedWithLensPosition:lensPosition completionHandler:nil];
            
            [currentVideoDevice unlockForConfiguration];
        }
    }
}

- (void)cameraManagerExposureIOS:(CGFloat)iso
{
    if (iso >= self.camera.inputCamera.activeFormat.maxISO) {
        iso = self.camera.inputCamera.activeFormat.maxISO;
    }
    
    if (iso <= self.camera.inputCamera.activeFormat.minISO) {
        iso = self.camera.inputCamera.activeFormat.minISO;
    }
    
    NSError *error = nil;
    if ( [self.camera.inputCamera lockForConfiguration:&error] ) {
        [self.camera.inputCamera setExposureModeCustomWithDuration:AVCaptureExposureDurationCurrent ISO:iso completionHandler:nil];
        [self.camera.inputCamera unlockForConfiguration];
    }
    else {
        NSLog( @"Could not lock device for configuration: %@", error );
    }
}

static const float kExposureMinimumDuration = 1.0/1000;
static const float kExposureDurationPower = 5;
- (void)setExposureDurationWith:(CGFloat)value withBlock:(JYLableText)text
{
    NSError *error = nil;
    
    double p = pow( value, kExposureDurationPower ); // Apply power function to expand slider's low-end range
    double minDurationSeconds = MAX( CMTimeGetSeconds(self.camera.inputCamera.activeFormat.minExposureDuration ), kExposureMinimumDuration );
    double maxDurationSeconds = CMTimeGetSeconds(self.camera.inputCamera.activeFormat.maxExposureDuration );
    double newDurationSeconds = p * ( maxDurationSeconds - minDurationSeconds ) + minDurationSeconds; // Scale from 0-1 slider range to actual duration
    
    if ( [self.camera.inputCamera lockForConfiguration:&error] ) {
        [self.camera.inputCamera setExposureModeCustomWithDuration:CMTimeMakeWithSeconds( newDurationSeconds, 1000*1000*1000 )  ISO:AVCaptureISOCurrent completionHandler:nil];
        [self.camera.inputCamera unlockForConfiguration];
    }
    else {
        NSLog( @"Could not lock device for configuration: %@", error );
    }
}

#pragma mark -------------------------> 设置曝光补偿
// 设置曝光属性  ---> 曝光补偿
- (void)cameraManagerWithExposure:(CGFloat)value
{
    NSError *error = nil;
    AVCaptureDevice *currentVideoDevice = self.camera.inputCamera;
    
    [currentVideoDevice lockForConfiguration:&error];
    
    [currentVideoDevice setExposureTargetBias:value completionHandler:nil];
    
    [currentVideoDevice unlockForConfiguration];
}

- (void)cameraManagerVideoZoom:(CGFloat)zoom
{
    CGFloat value = 2.5 - 3 * zoom;
//        NSLog(@"赋值给系统 - %f", value);
    NSError *error = nil;
    AVCaptureDevice *currentVideoDevice = self.camera.inputCamera;
    
    [currentVideoDevice lockForConfiguration:&error];
    
    if (value >= currentVideoDevice.activeFormat.videoMaxZoomFactor) {
        value = currentVideoDevice.activeFormat.videoMaxZoomFactor;
    } else if (value <= 1.0)
    {
        value = 1.0;
    }
    
    currentVideoDevice.videoZoomFactor = value;
    //    NSLog(@"系统的对焦值 - %f", currentVideoDevice.videoZoomFactor);
    
    [currentVideoDevice unlockForConfiguration];
}


/** 设置相机的白平衡模式 */
- (void)whiteBalanceMode:(AVCaptureWhiteBalanceMode)whiteBalanceMode
{
    NSError *error = nil;
    
    if ([self.camera.inputCamera lockForConfiguration:&error]) {
        
        if ([self.camera.inputCamera isWhiteBalanceModeSupported:whiteBalanceMode] ) {
            self.camera.inputCamera.whiteBalanceMode = whiteBalanceMode;
        }
        
        [self.camera.inputCamera unlockForConfiguration];
        
    } else
    {
        NSLog(@"设置白平衡失败");
    }
}

/** 设置相机的曝光模式 */
- (void)exposeMode:(AVCaptureExposureMode)exposureMode
{
    NSError *error = nil;
    AVCaptureDevice *currentVideoDevice = self.camera.inputCamera;
    
    if ([currentVideoDevice lockForConfiguration:&error]) {
        
        if ( currentVideoDevice.isExposurePointOfInterestSupported && [currentVideoDevice isExposureModeSupported:exposureMode] ) {
            currentVideoDevice.exposureMode = exposureMode;
        }
        
        [currentVideoDevice unlockForConfiguration];
        
    } else
    {
        NSLog(@"设置曝光失败");
    }
}

- (void)flashModel:(AVCaptureFlashMode)flashModel
{
    NSError *error = nil;
    AVCaptureDevice *currentVideoDevice = self.camera.inputCamera;
    
    if ([currentVideoDevice lockForConfiguration:&error]) {
        
        if ([currentVideoDevice isFlashModeSupported:flashModel] ) {
            currentVideoDevice.flashMode = flashModel;
        }
        
        [currentVideoDevice unlockForConfiguration];
        
    } else
    {
        NSLog(@"设置闪关灯失败");
    }
}

- (void)cameraManagerBalanceGainsWithTemp:(CGFloat)temp andTint:(CGFloat)tint
{
    AVCaptureWhiteBalanceTemperatureAndTintValues temperatureAndTint = {
        .temperature = temp,
        .tint = tint,
    };
    [self cameraManagerSetWhiteBalanceGains:[self.camera.inputCamera deviceWhiteBalanceGainsForTemperatureAndTintValues:temperatureAndTint]];
}

- (void)cameraManagerSetWhiteBalanceGains:(AVCaptureWhiteBalanceGains)gains
{
    NSError *error = nil;
    AVCaptureDevice *currentVideoDevice = self.camera.inputCamera;
    if ( [currentVideoDevice lockForConfiguration:&error] ) {
        AVCaptureWhiteBalanceGains normalizedGains = [self normalizedGains:gains]; // Conversion can yield out-of-bound values, cap to limits
        [currentVideoDevice setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains:normalizedGains completionHandler:nil];
        [currentVideoDevice unlockForConfiguration];
    }
    else {
        NSLog( @"Could not lock device for configuration: %@", error );
    }
}

- (AVCaptureWhiteBalanceGains)normalizedGains:(AVCaptureWhiteBalanceGains) gains
{
    AVCaptureWhiteBalanceGains g = gains;
    
    g.redGain = MAX( 1.0, g.redGain );
    g.greenGain = MAX( 1.0, g.greenGain );
    g.blueGain = MAX( 1.0, g.blueGain );
    
    g.redGain = MIN( self.camera.inputCamera.maxWhiteBalanceGain, g.redGain );
    g.greenGain = MIN( self.camera.inputCamera.maxWhiteBalanceGain, g.greenGain );
    g.blueGain = MIN( self.camera.inputCamera.maxWhiteBalanceGain, g.blueGain );
    
    return g;
}


+ (void)setFlashMode:(AVCaptureFlashMode)flashMode forDevice:(AVCaptureDevice *)device
{
    if ( device.hasFlash && [device isFlashModeSupported:flashMode] ) {
        NSError *error = nil;
        if ( [device lockForConfiguration:&error] ) {
            device.flashMode = flashMode;
            [device unlockForConfiguration];
        }
        else {
            NSLog( @"Could not lock device for configuration: %@", error );
        }
    }
}

/** 设置相机拍摄质量 */
- (void)cameraManagerEffectqualityWithTag:(NSInteger)tag withBlock:(CanSetSessionPreset)canSetSessionPreset
{
    NSError *error = nil;
    
    AVCaptureDevice *videoDevice = [JYCameraManager deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
    AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    
    if ( ! videoDeviceInput ) {
        NSLog( @"Could not create video device input: %@", error );
    }
    
    [self.camera.captureSession beginConfiguration];
    
    NSString *sessionPreset = nil;
    
    switch (tag) {
            
        case 60:
            sessionPreset = AVCaptureSessionPreset640x480;
            break;
        case 61:
            sessionPreset = AVCaptureSessionPreset1280x720;
            break;
        case 62:
            sessionPreset = AVCaptureSessionPresetHigh;
            break;
        case 63:
            sessionPreset = AVCaptureSessionPreset3840x2160;
            break;
        default:
            sessionPreset = AVCaptureSessionPresetHigh;
            break;
    }
    if ([self.camera.captureSession canSetSessionPreset:sessionPreset])
    {
        self.camera.captureSession.sessionPreset = sessionPreset;
        
        // 2.偏好设置保存选中的分辨率
        [[NSUserDefaults standardUserDefaults] setInteger:tag forKey:@"imageViewSeleted"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
    } else{
        canSetSessionPreset(NO);
    }
    
    
    if ( [self.camera.captureSession canAddInput:videoDeviceInput] ) {
        [self.camera.captureSession addInput:videoDeviceInput];
        self.camera.deviceInput = videoDeviceInput;
    }
    
    [self.camera.captureSession commitConfiguration];
    //    });
}

#pragma mark -------------------------> 更改操作
// 设置闪关灯
- (void)setEnableFlash:(BOOL)enableFlash
{
    _enableFlash = enableFlash;
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasTorch] && [device hasFlash])
    {
        [device lockForConfiguration:nil];
        if (enableFlash) { [device setTorchMode:AVCaptureTorchModeOn]; }
        else { [device setTorchMode:AVCaptureTorchModeOff]; }
        [device unlockForConfiguration];
    }
}

#pragma mark -------------------------> 设置曝光时间 和 感光度
- (void)videoCameraWithExposureTime:(CGFloat)time andIso:(CGFloat)iso
{
    NSError *error = nil;
    AVCaptureDevice *currentVideoDevice = self.camera.inputCamera;
    
    [currentVideoDevice lockForConfiguration:&error];
    
    //        AVCaptureDeviceFormat *deviceFormat = self.captureDevice.activeFormat;
    //
    //        NSLog(@"%f =%f", deviceFormat.maxISO, deviceFormat.minISO);
    CMTime timea = CMTimeMake(time, 1000000);
    
    [currentVideoDevice setExposureModeCustomWithDuration:timea ISO:iso completionHandler:^(CMTime syncTime) {
        
    }];
    //    CMTime time = CMTimeMake(125, 1000000);
    //    CMTime time1 = CMTimeMake(333333, 1000000);
    //    NSLog(@"%f  == %f",CMTimeGetSeconds(time), CMTimeGetSeconds(time1));
    //    NSLog(@"%f == %f",deviceFormat.minISO, deviceFormat.maxISO);
    [currentVideoDevice unlockForConfiguration];
}

+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = devices.firstObject;
    
    for ( AVCaptureDevice *device in devices ) {
        if ( device.position == position ) {
            captureDevice = device;
            break;
        }
    }
    
    return captureDevice;
}

@end

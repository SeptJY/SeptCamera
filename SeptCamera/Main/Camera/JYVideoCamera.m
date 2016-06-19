//
//  JYVideoCamera.m
//  TestVideo
//
//  Created by Sept on 16/5/26.
//  Copyright © 2016年 九月. All rights reserved.
//

#import "JYVideoCamera.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface JYVideoCamera () <GPUImageMovieWriterDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, GPUImageVideoCameraDelegate>
{
    CMTime defaultVideoMaxFrameDuration;
    dispatch_queue_t movieWritingQueue;
    CMBufferQueueRef previewBufferQueue;
    NSArray *_bracketSettings;
    
    BOOL readyToRecordAudio;
    BOOL readyToRecordVideo;
    AVCaptureVideoOrientation videoOrientation;
    AVCaptureVideoOrientation referenceOrientation;
    BOOL recordingWillBeStarted;
    NSURL *_url;
}

@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterVideoInput;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterAudioInput;
@property (nonatomic, strong) AVCaptureConnection *audioConnection;
@property (nonatomic, strong) AVCaptureConnection *videoConnection;

@property (strong, nonatomic) GPUImageView *filteredVideoView;

@property (strong, nonatomic) UIView *superView;

@property (nonatomic, strong) AVCaptureDeviceFormat *defaultFormat;



@end


@implementation JYVideoCamera

- (instancetype)initWithSessionPreset:(NSString *)sessionPreset superView:(UIView *)superView
{
    self = [super init];
    if (self) {
        
        movieWritingQueue = dispatch_queue_create("com.shu223.moviewriting", DISPATCH_QUEUE_SERIAL);
        referenceOrientation = (AVCaptureVideoOrientation)UIDeviceOrientationPortrait;
        self.sessionPreset = sessionPreset;
        self.superView = superView;
        
        self.videoSize = CGSizeMake(1280, 720);
        
        self.quality = ([[NSUserDefaults standardUserDefaults] floatForKey:@"CodingQuality"] == 0) ? 5.0f : [[NSUserDefaults standardUserDefaults] floatForKey:@"CodingQuality"];
        
        self.imgsArray = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)startCamera
{
    [self.videoCamera startCameraCapture];
}

- (void)stopCamera
{
    [self.videoCamera stopCameraCapture];
}

- (GPUImageView *)scaleView
{
    if (!_scaleView) {
        _scaleView = [[GPUImageView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
        _scaleView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
        _scaleView.transform = CGAffineTransformMakeScale(4.0, 4.0);
    }
    return _scaleView;
}

- (GPUImageView *)filteredVideoView
{
    if (!_filteredVideoView) {
        
        _filteredVideoView = [[GPUImageView alloc] init];
        
        _filteredVideoView.frame = self.superView.bounds;
        _filteredVideoView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
        [self.superView addSubview:_filteredVideoView];
    }
    return _filteredVideoView;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self.videoCamera startCameraCapture];
    }
    return self;
}

- (void)movieRecordingCompleted:(NSURL *)url
{
    //    NSLog(@"ABSBSBBSBSB");
        if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManagerRecodingSuccess:)]) {
            [self.delegate cameraManagerRecodingSuccess:url];
        }
}

- (void)prepareBracketsWith:(NSInteger)index
{
    switch (index) {
        case 0:
            
            break;
        case 1:
            
            break;
            
        default:
            break;
    }
}

- (void)takePhotosWithHDR
{
    [self.videoCamera startBracketsCompletionHandler:^(UIImage *image) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    }];
}

- (void)prepareHDRWithIndex:(NSInteger)index
{
    [self.videoCamera prepareBracketsWithIndex:index];
}

- (void)takePhoto
{
    [self.videoCamera capturePhotoAsImageProcessedUpToFilter:self.filter withOrientation:UIImageOrientationUp withCompletionHandler:^(UIImage *processedImage, NSError *error) {
        
        UIImageWriteToSavedPhotosAlbum(processedImage, nil, nil, nil);
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManageTakingPhotoSucuess:)]) {
            [self.delegate cameraManageTakingPhotoSucuess:processedImage];
        }
    }];
}

- (void)setFrameRate:(int32_t)frameRate
{
    self.videoCamera.frameRate = frameRate;
}

- (void)resetFormats
{
    [self.videoCamera resetFormat];
}

- (void)aswitchFormatWithDesiredFPS:(CGFloat)desiredFPS
{
    [self.videoCamera switchFormatWithDesiredFPS:desiredFPS];
}

- (void)takePhotoWithArray
{
    [self.videoCamera capturePhotoAsImageProcessedUpToFilter:self.filter withOrientation:UIImageOrientationUp withCompletionHandler:^(UIImage *processedImage, NSError *error) {
        
//        UIImageWriteToSavedPhotosAlbum(processedImage, nil, nil, nil);
        NSLog(@"%@", processedImage);
        if (processedImage) {
            [self.imgsArray addObject:processedImage];
        }
//        if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManageTakingPhotoSucuessArray:)]) {
//            [self.delegate cameraManageTakingPhotoSucuessArray:self.imgsArray];
//        }
        
//        if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManageTakingPhotoSucuess:)]) {
//            [self.delegate cameraManageTakingPhotoSucuess:processedImage];
//        }
    }];
}

- (void)startVideo
{
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
    NSString* dateTimePrefix = [formatter stringFromDate:[NSDate date]];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    int fileNamePostfix = 0;
    
    do
        self.pathToMovie =[NSString stringWithFormat:@"/%@/%@-%i.MOV", documentsDirectory, dateTimePrefix, fileNamePostfix++];
    while ([[NSFileManager defaultManager] fileExistsAtPath:self.pathToMovie]);
    
    NSURL *movieURL = [NSURL URLWithString:[@"file://" stringByAppendingString:self.pathToMovie]];
    
//    self.pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.MOV"];
//    unlink([self.pathToMovie UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
//    NSURL *movieURL = [NSURL fileURLWithPath:self.pathToMovie];
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:self.videoSize quality:self.quality];
    
    movieWriter.delegate = self;
    movieWriter.encodingLiveVideo = YES;
    movieWriter.shouldPassthroughAudio = YES;
    [self.filter addTarget:movieWriter];
    self.videoCamera.audioEncodingTarget = movieWriter;
    [movieWriter startRecording];
}

- (void)aaaaaaaaa
{
    [self.videoCamera stopCameraCapture];
//    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
//    [formatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
//    NSString* dateTimePrefix = [formatter stringFromDate:[NSDate date]];
//    
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    
//    dispatch_async(movieWritingQueue, ^{
//        
//        UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
//        // Don't update the reference orientation when the device orientation is face up/down or unknown.
//        if (UIDeviceOrientationIsPortrait(orientation) || UIDeviceOrientationIsLandscape(orientation)) {
//            referenceOrientation = (AVCaptureVideoOrientation)orientation;
//        }
//        
//        int fileNamePostfix = 0;
//        NSString *filePath = nil;
//        
//        do
//            filePath =[NSString stringWithFormat:@"/%@/%@-%i.MOV", documentsDirectory, dateTimePrefix, fileNamePostfix++];
//        while ([[NSFileManager defaultManager] fileExistsAtPath:filePath]);
//        
//        _url = [NSURL URLWithString:[@"file://" stringByAppendingString:filePath]];
//        
//        NSError *error;
//        self.assetWriter = [[AVAssetWriter alloc] initWithURL:_url
//                                                     fileType:AVFileTypeQuickTimeMovie
//                                                        error:&error];
//        NSLog(@"AVAssetWriter error:%@", error);
//        
//        recordingWillBeStarted = YES;
    
//                [self.assetWriter startWriting];
//                [self.assetWriter startSessionAtSourceTime:kCMTimeZero];
//    });
}

- (void)bbbbbbbbbbb
{
    [self.videoCamera startCameraCapture];
//    [self.videoCamera fpsStopRecoding];
//    dispatch_async(movieWritingQueue, ^{
//        
//        self.isRecording = NO;
//        readyToRecordVideo = NO;
//        readyToRecordAudio = NO;
//        
//        [self.assetWriter finishWritingWithCompletionHandler:^{
//            
//            self.assetWriterVideoInput = nil;
//            self.assetWriterAudioInput = nil;
//            self.assetWriter = nil;
//            
//            dispatch_async(dispatch_get_main_queue(), ^{
//                
////                if ([self.delegate respondsToSelector:@selector(didFinishRecordingToOutputFileAtURL:error:)]) {
////                    [self.delegate didFinishRecordingToOutputFileAtURL:_url error:nil];
////                }
//                [self saveRecordedFile:_url];
//            });
//        }];
//    });
}

- (void)movieRecordingvideoSaveSuccess:(NSURL *)url
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManagerRecodingSuccess:)]) {
        [self.delegate cameraManagerRecodingSuccess:url];
    }
}

- (void)didFinishRecordingToOutputFileAtURL:(NSURL *)url error:(NSError *)error
{
    LOG_CURRENT_METHOD;
    if (error) {
        NSLog(@"error:%@", error);
        return;
    }
    
//    if (!isNeededToSave) {
//        return;
//    }
    
    [self saveRecordedFile:url];
}

- (void)saveRecordedFile:(NSURL *)recordedFile {
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
        [assetLibrary writeVideoAtPathToSavedPhotosAlbum:recordedFile
                                         completionBlock:
         ^(NSURL *assetURL, NSError *error) {
             
             dispatch_async(dispatch_get_main_queue(), ^{
                 
                 NSString *title;
                 NSString *message;
                 
                 if (error != nil) {
                     
                     title = @"Failed to save video";
                     message = [error localizedDescription];
                 }
                 else {
                     title = @"Saved!";
                     message = nil;
                 }
                 
                 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                                 message:message
                                                                delegate:nil
                                                       cancelButtonTitle:@"OK"
                                                       otherButtonTitles:nil];
                 [alert show];
             });
         }];
    });
}


- (void)stopVideo
{
    self.videoCamera.audioEncodingTarget = nil;
    UISaveVideoAtPathToSavedPhotosAlbum(self.pathToMovie, nil, nil, nil);
    [movieWriter finishRecording];
    [self.filter removeTarget:movieWriter];
}

- (GPUImageFilterGroup *)filter
{
    if (!_filter) {
        _filter = [[GPUImageFilterGroup alloc] init];
        
        self.exposureFilter = [[GPUImageExposureFilter alloc] init];
        self.saturationFilter = [[GPUImageSaturationFilter alloc] init];
//        self.lowPassFilter = [[GPUImageLowPassFilter alloc] init];
        
        [self.exposureFilter addTarget:self.saturationFilter];
        
        [(GPUImageFilterGroup *) _filter setInitialFilters:[NSArray arrayWithObject: self.exposureFilter]];
        [(GPUImageFilterGroup *) _filter setTerminalFilter:self.saturationFilter];
        
        [_filter addTarget:self.filteredVideoView];
        [_filter addTarget:self.scaleView];
    }
    return _filter;
}

- (GPUImageStillCamera *)videoCamera
{
    if (!_videoCamera) {
        _videoCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:self.sessionPreset cameraPosition:AVCaptureDevicePositionBack];
        _videoCamera.outputImageOrientation = UIInterfaceOrientationLandscapeRight;
        [_videoCamera addAudioInputsAndOutputs];
        [_videoCamera addTarget:self.filter];
        _videoCamera.delegate =  self;
        self.videoConnection = [_videoCamera AVCaptureConnection1];
//        _videoCamera.frameRate = 120;
    }
    return _videoCamera;
}

#pragma mark -------------------------> GPUImageStillCameraDelegate

- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (self.onBuffer) {
        self.onBuffer(sampleBuffer);
    }
    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
    
    CFRetain(sampleBuffer);
    
    dispatch_async(movieWritingQueue, ^{
//        NSLog(@"%@ - %d, -%d", self.assetWriter, self.isRecording, recordingWillBeStarted);
        if (self.assetWriter && (self.isRecording || recordingWillBeStarted)) {
            
            BOOL wasReadyToRecord = (readyToRecordAudio && readyToRecordVideo);
            if (connection == self.videoConnection) {
                
                // Initialize the video input if this is not done yet
                if (!readyToRecordVideo) {
                    
                    readyToRecordVideo = [self setupAssetWriterVideoInput:formatDescription];
                }
                
                // Write video data to file
                NSLog(@"%d --- %d", readyToRecordAudio, readyToRecordVideo);
                if (readyToRecordVideo && readyToRecordAudio) {
                    [self writeSampleBuffer:sampleBuffer ofType:AVMediaTypeVideo];
                }
            }
            
            else if (connection == self.videoCamera.audioConnection) {
                
                // Initialize the audio input if this is not done yet
                if (!readyToRecordAudio) {
                    readyToRecordAudio = [self setupAssetWriterAudioInput:formatDescription];
                }
                
                // Write audio data to file
                if (readyToRecordAudio && readyToRecordVideo)
                    [self writeSampleBuffer:sampleBuffer ofType:AVMediaTypeAudio];
            }
            
            BOOL isReadyToRecord = (readyToRecordAudio && readyToRecordVideo);
            NSLog(@"%d --- %d", wasReadyToRecord, isReadyToRecord);
            if (!wasReadyToRecord && isReadyToRecord) {
                
                recordingWillBeStarted = NO;
                self.isRecording = YES;
            }
        }
        CFRelease(sampleBuffer);
    });
}

- (BOOL)setupAssetWriterVideoInput:(CMFormatDescriptionRef)currentFormatDescription
{
    float bitsPerPixel;
    CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(currentFormatDescription);
    int numPixels = dimensions.width * dimensions.height;
    int bitsPerSecond;
    
    // Assume that lower-than-SD resolutions are intended for streaming, and use a lower bitrate
    if ( numPixels < (640 * 480) )
        bitsPerPixel = 4.05; // This bitrate matches the quality produced by AVCaptureSessionPresetMedium or Low.
    else
        bitsPerPixel = 11.4; // This bitrate matches the quality produced by AVCaptureSessionPresetHigh.
    
    bitsPerSecond = numPixels * bitsPerPixel;
    
    NSDictionary *videoCompressionSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                              AVVideoCodecH264, AVVideoCodecKey,
                                              [NSNumber numberWithInteger:dimensions.width], AVVideoWidthKey,
                                              [NSNumber numberWithInteger:dimensions.height], AVVideoHeightKey,
                                              [NSDictionary dictionaryWithObjectsAndKeys:
                                               [NSNumber numberWithInteger:bitsPerSecond], AVVideoAverageBitRateKey,
                                               [NSNumber numberWithInteger:30], AVVideoMaxKeyFrameIntervalKey,
                                               nil], AVVideoCompressionPropertiesKey,
                                              nil];
    
    NSLog(@"videoCompressionSetting:%@", videoCompressionSettings);
    
    if ([self.assetWriter canApplyOutputSettings:videoCompressionSettings forMediaType:AVMediaTypeVideo]) {
        
        self.assetWriterVideoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo
                                                                    outputSettings:videoCompressionSettings];
        
        self.assetWriterVideoInput.expectsMediaDataInRealTime = YES;
        self.assetWriterVideoInput.transform = [self transformFromCurrentVideoOrientationToOrientation:referenceOrientation];
        
        if ([self.assetWriter canAddInput:self.assetWriterVideoInput]) {
            
            [self.assetWriter addInput:self.assetWriterVideoInput];
        }
        else {
            
            NSLog(@"Couldn't add asset writer video input.");
            return NO;
        }
    }
    else {
        
        NSLog(@"Couldn't apply video output settings.");
        return NO;
    }
    
    return YES;
}

- (CGAffineTransform)transformFromCurrentVideoOrientationToOrientation:(AVCaptureVideoOrientation)orientation
{
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    // Calculate offsets from an arbitrary reference orientation (portrait)
    CGFloat orientationAngleOffset = [JYVideoCamera angleOffsetFromPortraitOrientationToOrientation:orientation];
    CGFloat videoOrientationAngleOffset = [JYVideoCamera angleOffsetFromPortraitOrientationToOrientation:videoOrientation];
    
    // Find the difference in angle between the passed in orientation and the current video orientation
    CGFloat angleOffset = orientationAngleOffset - videoOrientationAngleOffset;
    transform = CGAffineTransformMakeRotation(angleOffset);
    
    return transform;
}

+ (CGFloat)angleOffsetFromPortraitOrientationToOrientation:(AVCaptureVideoOrientation)orientation
{
    CGFloat angle = 0.0;
    
    switch (orientation) {
        case AVCaptureVideoOrientationPortrait:
            angle = 0.0;
            break;
        case AVCaptureVideoOrientationPortraitUpsideDown:
            angle = M_PI;
            break;
        case AVCaptureVideoOrientationLandscapeRight:
            angle = -M_PI_2;
            break;
        case AVCaptureVideoOrientationLandscapeLeft:
            angle = M_PI_2;
            break;
        default:
            break;
    }
    
    return angle;
}


- (BOOL)setupAssetWriterAudioInput:(CMFormatDescriptionRef)currentFormatDescription
{
    const AudioStreamBasicDescription *currentASBD = CMAudioFormatDescriptionGetStreamBasicDescription(currentFormatDescription);
    
    size_t aclSize = 0;
    const AudioChannelLayout *currentChannelLayout = CMAudioFormatDescriptionGetChannelLayout(currentFormatDescription, &aclSize);
    NSData *currentChannelLayoutData = nil;
    
    // AVChannelLayoutKey must be specified, but if we don't know any better give an empty data and let AVAssetWriter decide.
    if ( currentChannelLayout && aclSize > 0 ) {
        
        currentChannelLayoutData = [NSData dataWithBytes:currentChannelLayout length:aclSize];
    }
    else {
        
        currentChannelLayoutData = [NSData data];
    }
    
    NSDictionary *audioCompressionSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                              [NSNumber numberWithInteger:kAudioFormatMPEG4AAC], AVFormatIDKey,
                                              [NSNumber numberWithFloat:currentASBD->mSampleRate], AVSampleRateKey,
                                              [NSNumber numberWithInt:64000], AVEncoderBitRatePerChannelKey,
                                              [NSNumber numberWithInteger:currentASBD->mChannelsPerFrame], AVNumberOfChannelsKey,
                                              currentChannelLayoutData, AVChannelLayoutKey,
                                              nil];
    if ([self.assetWriter canApplyOutputSettings:audioCompressionSettings forMediaType:AVMediaTypeAudio]) {
        
        self.assetWriterAudioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio
                                                                    outputSettings:audioCompressionSettings];
        
        self.assetWriterAudioInput.expectsMediaDataInRealTime = YES;
        
        if ([self.assetWriter canAddInput:self.assetWriterAudioInput]) {
            
            [self.assetWriter addInput:self.assetWriterAudioInput];
        }
        else {
            
            NSLog(@"Couldn't add asset writer audio input.");
            return NO;
        }
    }
    else {
        
        NSLog(@"Couldn't apply audio output settings.");
        return NO;
    }
    
    return YES;
}

- (void)writeSampleBuffer:(CMSampleBufferRef)sampleBuffer
                   ofType:(NSString *)mediaType
{
    if (self.assetWriter.status == AVAssetWriterStatusUnknown) {
        
        if ([self.assetWriter startWriting]) {
            
            CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            [self.assetWriter startSessionAtSourceTime:timestamp];
        }
        else {
            
            NSLog(@"AVAssetWriter startWriting error:%@", self.assetWriter.error);
        }
    }
    
    if (self.assetWriter.status == AVAssetWriterStatusWriting) {
        
        if (mediaType == AVMediaTypeVideo) {
            
            if (self.assetWriterVideoInput.readyForMoreMediaData) {
                
                if (![self.assetWriterVideoInput appendSampleBuffer:sampleBuffer]) {
                    
                    NSLog(@"isRecording:%d, willBeStarted:%d", self.isRecording, recordingWillBeStarted);
                    NSLog(@"AVAssetWriterInput video appendSapleBuffer error:%@", self.assetWriter.error);
                }
            }
        }
        else if (mediaType == AVMediaTypeAudio) {
            
            if (self.assetWriterAudioInput.readyForMoreMediaData) {
                
                if (![self.assetWriterAudioInput appendSampleBuffer:sampleBuffer]) {
                    
                    NSLog(@"AVAssetWriterInput audio appendSapleBuffer error:%@", self.assetWriter.error);
                }
            }
        }
    }
}


#pragma mark -------------------------> 调焦焦距
- (void)cameraManagerChangeFoucus:(CGFloat)value
{
    //    NSLog(@"%f", value);d
    CGFloat lensPosition = value - 0.5;
    if (self.videoCamera.inputCamera.position == AVCaptureDevicePositionBack) {
        if (lensPosition < 0) {
            lensPosition = 0;
        }
        
        if (lensPosition > 1) {
            lensPosition = 1;
        }
        
        NSError *error = nil;
        AVCaptureDevice *currentVideoDevice = self.videoCamera.inputCamera;
        if ([currentVideoDevice lockForConfiguration:&error]) {
            
            [currentVideoDevice setAutoFocusRangeRestriction:AVCaptureAutoFocusRangeRestrictionNone];
            
            [currentVideoDevice setFocusModeLockedWithLensPosition:lensPosition completionHandler:nil];
            
            [currentVideoDevice unlockForConfiguration];
        }
    }
}

#pragma mark -------------------------> 设置曝光时间 和 感光度
- (void)videoCameraWithExposureTime:(CGFloat)time andIso:(CGFloat)iso
{
    NSError *error = nil;
    AVCaptureDevice *currentVideoDevice = self.videoCamera.inputCamera;
    
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

/** 设置相机拍摄质量 */
- (void)cameraManagerEffectqualityWithTag:(NSInteger)tag withBlock:(CanSetSessionPreset)canSetSessionPreset
{
    NSError *error = nil;
    
    AVCaptureDevice *videoDevice = [JYVideoCamera deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
    AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    
    if ( ! videoDeviceInput ) {
        NSLog( @"Could not create video device input: %@", error );
    }
    
    [self.videoCamera.captureSession beginConfiguration];
    
    NSString *sessionPreset = nil;
    
    switch (tag) {
            
        case 60:
            sessionPreset = AVCaptureSessionPreset640x480;
            break;
        case 61:
            sessionPreset = AVCaptureSessionPreset1280x720;
            break;
        case 62:
            sessionPreset = AVCaptureSessionPreset1920x1080;
            break;
        case 63:
            sessionPreset = AVCaptureSessionPreset3840x2160;
            break;
        default:
            sessionPreset = AVCaptureSessionPreset1920x1080;
            break;
    }
    if ([self.videoCamera.captureSession canSetSessionPreset:sessionPreset])
    {
        [self.videoCamera setCaptureSessionPreset:sessionPreset];
        
        self.videoSize = [self getVideoSizeWith:sessionPreset];
        
        // 2.偏好设置保存选中的分辨率
        [[NSUserDefaults standardUserDefaults] setInteger:tag forKey:@"imageViewSeleted"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else{
        canSetSessionPreset(NO);
    }
    
    
    if ( [self.videoCamera.captureSession canAddInput:videoDeviceInput] ) {
        [self.videoCamera.captureSession addInput:videoDeviceInput];
    }
    
    [self.videoCamera.captureSession commitConfiguration];
    //    });
}

- (CGSize)getVideoSizeWith:(NSString *)sessionPreset
{
    NSRegularExpression *regular = [NSRegularExpression regularExpressionWithPattern:@"[a-zA-Z.-]" options:0 error:NULL];
    NSString *result = [regular stringByReplacingMatchesInString:sessionPreset options:0 range:NSMakeRange(0, [sessionPreset length]) withTemplate:@""];
    
    NSRange rang = [result rangeOfString:@"0"];
    NSString *width = [result substringWithRange:NSMakeRange(0, rang.location + 1)];
    NSString *height = [result substringWithRange:NSMakeRange(rang.location + 1, result.length - rang.location - 1)];
    
    CGSize videoSize = CGSizeMake([width floatValue], [height floatValue]);
    
    return videoSize;
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

- (void)flashModel:(AVCaptureFlashMode)flashModel
{
    NSError *error = nil;
    AVCaptureDevice *currentVideoDevice = self.videoCamera.inputCamera;
    
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

- (void)cameraManagerVideoZoom:(CGFloat)zoom
{
    CGFloat value = zoom;
    //        NSLog(@"赋值给系统 - %f", value);
    NSError *error = nil;
    AVCaptureDevice *currentVideoDevice = self.videoCamera.inputCamera;
    
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

- (void)cameraManagerSetWhiteBalanceGains:(AVCaptureWhiteBalanceGains)gains
{
    NSError *error = nil;
    AVCaptureDevice *currentVideoDevice = self.videoCamera.inputCamera;
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
    
    g.redGain = MIN(self.videoCamera.inputCamera.maxWhiteBalanceGain, g.redGain );
    g.greenGain = MIN( self.videoCamera.inputCamera.maxWhiteBalanceGain, g.greenGain );
    g.blueGain = MIN( self.videoCamera.inputCamera.maxWhiteBalanceGain, g.blueGain );
    
    return g;
}

/** 设置相机的白平衡模式 */
- (void)whiteBalanceMode:(AVCaptureWhiteBalanceMode)whiteBalanceMode
{
    NSError *error = nil;
    
    if ([self.videoCamera.inputCamera lockForConfiguration:&error]) {
        
        if ([self.videoCamera.inputCamera isWhiteBalanceModeSupported:whiteBalanceMode] ) {
            self.videoCamera.inputCamera.whiteBalanceMode = whiteBalanceMode;
        }
        
        [self.videoCamera.inputCamera unlockForConfiguration];
        
    } else
    {
        NSLog(@"设置白平衡失败");
    }
}

- (void)cameraManagerBalanceGainsWithTemp:(CGFloat)temp andTint:(CGFloat)tint
{
    AVCaptureWhiteBalanceTemperatureAndTintValues temperatureAndTint = {
        .temperature = temp,
        .tint = tint,
    };
    [self cameraManagerSetWhiteBalanceGains:[self.videoCamera.inputCamera deviceWhiteBalanceGainsForTemperatureAndTintValues:temperatureAndTint]];
}

- (void)cameraManagerExposureIOS:(CGFloat)iso
{
    if (iso >= self.videoCamera.inputCamera.activeFormat.maxISO) {
        iso = self.videoCamera.inputCamera.activeFormat.maxISO;
    }
    
    if (iso <= self.videoCamera.inputCamera.activeFormat.minISO) {
        iso = self.videoCamera.inputCamera.activeFormat.minISO;
    }
    
    NSError *error = nil;
    if ( [self.videoCamera.inputCamera lockForConfiguration:&error] ) {
        [self.videoCamera.inputCamera setExposureModeCustomWithDuration:AVCaptureExposureDurationCurrent ISO:iso completionHandler:nil];
        [self.videoCamera.inputCamera unlockForConfiguration];
    }
    else {
        NSLog( @"Could not lock device for configuration: %@", error );
    }
}

static const float kExposureMinimumDuration = 1.0/1000;
static const float kExposureDurationPower = 5;
- (void)setExposureDurationWith:(CGFloat)value
{
    NSError *error = nil;
    
    double p = pow( value, kExposureDurationPower ); // Apply power function to expand slider's low-end range
    double minDurationSeconds = MAX( CMTimeGetSeconds(self.videoCamera.inputCamera.activeFormat.minExposureDuration ), kExposureMinimumDuration );
    double maxDurationSeconds = CMTimeGetSeconds(self.videoCamera.inputCamera.activeFormat.maxExposureDuration );
    double newDurationSeconds = p * ( maxDurationSeconds - minDurationSeconds ) + minDurationSeconds; // Scale from 0-1 slider range to actual duration
    
    if ( [self.videoCamera.inputCamera lockForConfiguration:&error] ) {
        [self.videoCamera.inputCamera setExposureModeCustomWithDuration:CMTimeMakeWithSeconds( newDurationSeconds, 1000*1000*1000 )  ISO:AVCaptureISOCurrent completionHandler:nil];
        [self.videoCamera.inputCamera unlockForConfiguration];
    }
    else {
        NSLog( @"Could not lock device for configuration: %@", error );
    }
}

/** 设置相机的曝光模式 */
- (void)exposeMode:(AVCaptureExposureMode)exposureMode
{
    NSError *error = nil;
    AVCaptureDevice *currentVideoDevice = self.videoCamera.inputCamera;
    
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

- (void)switchFormatWithDesiredFPS:(CGFloat)desiredFPS
{
    BOOL isRunning = self.videoCamera.captureSession.isRunning;
    
    if (isRunning)  [self.videoCamera.captureSession stopRunning];
    
    AVCaptureDeviceFormat *selectedFormat = nil;
    AVFrameRateRange *frameRateRange = nil;
    
    for (AVCaptureDeviceFormat *format in [self.videoCamera.inputCamera formats]) {
        
        for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges) {
            
            CMFormatDescriptionRef desc = format.formatDescription;
            CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(desc);
            int32_t width = dimensions.width;
            if (range.minFrameRate <= desiredFPS && width == (int)self.videoSize.width && range.maxFrameRate == desiredFPS) {
                
                selectedFormat = format;
                frameRateRange = range;
            }
        }
    }
    
    if (selectedFormat) {
        
        if ([self.videoCamera.inputCamera lockForConfiguration:nil]) {
            
            CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(selectedFormat.formatDescription);
            self.videoSize = CGSizeMake(dimensions.width, dimensions.height);
            
            self.videoCamera.inputCamera.activeFormat = selectedFormat;
            self.videoCamera.inputCamera.activeVideoMinFrameDuration = CMTimeMake(1, (int32_t)desiredFPS);
            self.videoCamera.inputCamera.activeVideoMaxFrameDuration = CMTimeMake(1, (int32_t)desiredFPS);
            [self.videoCamera.inputCamera unlockForConfiguration];
        }
    }
    
    if (isRunning) [self.videoCamera.captureSession startRunning];
}

- (void)resetFormat {
    
    BOOL isRunning = self.videoCamera.captureSession.isRunning;
    
    if (isRunning) {
        [self.videoCamera.captureSession stopRunning];
    }
    
    //    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [self.videoCamera.inputCamera lockForConfiguration:nil];
    self.videoCamera.inputCamera.activeFormat = self.defaultFormat;
    self.videoCamera.inputCamera.activeVideoMaxFrameDuration = defaultVideoMaxFrameDuration;
    [self.videoCamera.inputCamera unlockForConfiguration];
    
    if (isRunning) {
        [self.videoCamera.captureSession startRunning];
    }
}

@end

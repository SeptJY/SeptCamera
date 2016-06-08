// 2448x3264 pixel image = 31,961,088 bytes for uncompressed RGBA

#import "GPUImageStillCamera.h"

#import <Photos/Photos.h>

#define CLAMP(_value, _lo, _hi) \
MAX( (_lo), MIN( (_hi), (_value) ) )
#define clamp(a) (a>255?255:(a<0?0:a))

void stillImageDataReleaseCallback(void *releaseRefCon, const void *baseAddress)
{
    free((void *)baseAddress);
}

void GPUImageCreateResizedSampleBuffer(CVPixelBufferRef cameraFrame, CGSize finalSize, CMSampleBufferRef *sampleBuffer)
{
    // CVPixelBufferCreateWithPlanarBytes for YUV input
    
    CGSize originalSize = CGSizeMake(CVPixelBufferGetWidth(cameraFrame), CVPixelBufferGetHeight(cameraFrame));

    CVPixelBufferLockBaseAddress(cameraFrame, 0);
    GLubyte *sourceImageBytes =  CVPixelBufferGetBaseAddress(cameraFrame);
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, sourceImageBytes, CVPixelBufferGetBytesPerRow(cameraFrame) * originalSize.height, NULL);
    CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();
    CGImageRef cgImageFromBytes = CGImageCreate((int)originalSize.width, (int)originalSize.height, 8, 32, CVPixelBufferGetBytesPerRow(cameraFrame), genericRGBColorspace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst, dataProvider, NULL, NO, kCGRenderingIntentDefault);
    
    GLubyte *imageData = (GLubyte *) calloc(1, (int)finalSize.width * (int)finalSize.height * 4);
    
    CGContextRef imageContext = CGBitmapContextCreate(imageData, (int)finalSize.width, (int)finalSize.height, 8, (int)finalSize.width * 4, genericRGBColorspace,  kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGContextDrawImage(imageContext, CGRectMake(0.0, 0.0, finalSize.width, finalSize.height), cgImageFromBytes);
    CGImageRelease(cgImageFromBytes);
    CGContextRelease(imageContext);
    CGColorSpaceRelease(genericRGBColorspace);
    CGDataProviderRelease(dataProvider);
    
    CVPixelBufferRef pixel_buffer = NULL;
    CVPixelBufferCreateWithBytes(kCFAllocatorDefault, finalSize.width, finalSize.height, kCVPixelFormatType_32BGRA, imageData, finalSize.width * 4, stillImageDataReleaseCallback, NULL, NULL, &pixel_buffer);
    CMVideoFormatDescriptionRef videoInfo = NULL;
    CMVideoFormatDescriptionCreateForImageBuffer(NULL, pixel_buffer, &videoInfo);
    
    CMTime frameTime = CMTimeMake(1, 30);
    CMSampleTimingInfo timing = {frameTime, frameTime, kCMTimeInvalid};
    
    CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, pixel_buffer, YES, NULL, NULL, videoInfo, &timing, sampleBuffer);
    CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
    CFRelease(videoInfo);
    CVPixelBufferRelease(pixel_buffer);
}

@interface GPUImageStillCamera ()
{
    AVCaptureStillImageOutput *photoOutput;
    NSArray *_bracketSettings;
    NSUInteger _maxBracketCount;
    
    // Size of the rendered striped image   呈现的条纹图像的大小
    CGSize _imageSize;
    
    // Size of a stripe  条纹尺寸
    CGSize _stripeSize;
    
    // Number of stripes before they repeat in the rendered image  在渲染图像中重复之前的条纹数
    NSUInteger _stride;
    
    // Current stripe index  当前条指数
    int _stripeIndex;
    CGContextRef _renderContext;
}

// Methods calling this are responsible for calling dispatch_semaphore_signal(frameRenderingSemaphore) somewhere inside the block
- (void)capturePhotoProcessedUpToFilter:(GPUImageOutput<GPUImageInput> *)finalFilterInChain withImageOnGPUHandler:(void (^)(NSError *error))block;

@end

@implementation GPUImageStillCamera {
    BOOL requiresFrontCameraTextureCacheCorruptionWorkaround;
}

@synthesize currentCaptureMetadata = _currentCaptureMetadata;
@synthesize jpegCompressionQuality = _jpegCompressionQuality;

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithSessionPreset:(NSString *)sessionPreset cameraPosition:(AVCaptureDevicePosition)cameraPosition;
{
    if (!(self = [super initWithSessionPreset:sessionPreset cameraPosition:cameraPosition]))
    {
		return nil;
    }
//    self.timer = [NSTimer scheduledTimerWithTimeInterval:500.0/1000 target:self selector:@selector(ruleImgViewTimer) userInfo:nil repeats:YES];
    
    /* Detect iOS version < 6 which require a texture cache corruption workaround */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    requiresFrontCameraTextureCacheCorruptionWorkaround = [[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] == NSOrderedAscending;
#pragma clang diagnostic pop
    
    [self.captureSession beginConfiguration];
    
    photoOutput = [[AVCaptureStillImageOutput alloc] init];
   
    // Having a still photo input set to BGRA and video to YUV doesn't work well, so since I don't have YUV resizing for iPhone 4 yet, kick back to BGRA for that device
//    if (captureAsYUV && [GPUImageContext supportsFastTextureUpload])
    if (captureAsYUV && [GPUImageContext deviceSupportsRedTextures])
    {
        BOOL supportsFullYUVRange = NO;
        NSArray *supportedPixelFormats = photoOutput.availableImageDataCVPixelFormatTypes;
        for (NSNumber *currentPixelFormat in supportedPixelFormats)
        {
            if ([currentPixelFormat intValue] == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
            {
                supportsFullYUVRange = YES;
            }
        }
        
        if (supportsFullYUVRange)
        {
            [photoOutput setOutputSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
        }
        else
        {
            [photoOutput setOutputSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
        }
    }
    else
    {
        captureAsYUV = NO;
        [photoOutput setOutputSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
        [videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    }
    
    [self.captureSession addOutput:photoOutput];
    
    [self.captureSession commitConfiguration];
    
    self.jpegCompressionQuality = 0.8;
    
    return self;
}

- (id)init;
{
    if (!(self = [self initWithSessionPreset:AVCaptureSessionPresetPhoto cameraPosition:AVCaptureDevicePositionBack]))
    {
		return nil;
    }
    return self;
}

- (void)removeInputsAndOutputs;
{
    [self.captureSession removeOutput:photoOutput];
    [super removeInputsAndOutputs];
}

- (void)startBracketsCompletionHandler:(AAPLCompletionWithImage)completion
{
    [photoOutput setOutputSettings:@{
                                     (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)
                                           // JPEG output
//                                           AVVideoCodecKey: AVVideoCodecJPEG
                                           /*
                                            * Or instead of JPEG, we can use one of the following pixel formats:
                                            *
                                            // BGRA
                                            (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)
                                            *
                                            // 420f output
                                            (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
                                            *
                                            */
                                           }];
//    NSLog(@"%@", photoOutput.outputSettings);
    // Number of brackets to capture
    __block int todo = (int)[_bracketSettings count];
    
    // Number of failed bracket captures
    __block int failed = 0;
    
    AVCaptureConnection *connection = [photoOutput connectionWithMediaType:AVMediaTypeVideo];
    [photoOutput captureStillImageBracketAsynchronouslyFromConnection:connection withSettingsArray:_bracketSettings completionHandler:^(CMSampleBufferRef sampleBuffer, AVCaptureBracketedStillImageSettings *stillImageSettings, NSError *error) {
        
        --todo;
        
        if (!error) {
//            NSLog(@"Bracket %@", stillImageSettings);
            
            // Process this sample buffer while we wait for the next bracketed image to be captured.
            // You would insert your own HDR algorithm here.
            [self addSampleBuffer:sampleBuffer];
        }
        else {
//            NSLog(@"This error should be handled appropriately in your app -- Bracket %@ ERROR: %@", stillImageSettings, error);
            
            ++failed;
        }
        
        // Return the rendered image strip when the capture completes
        if (!todo) {
            NSLog(@"All %d bracket(s) have been captured %@ error.", (int)[_bracketSettings count], (failed) ? @"with" : @"without");
            
            // This demo is restricted to portrait orientation for simplicity, where we hard-code the rendered striped image orientation.
            UIImage *image =
            (!failed)
            ? [self imageWithOrientation:UIImageOrientationUp]
            : nil;
            
            // Don't assume we're on the main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(image);
            });
        }
    }];
}

- (UIImage *)imageWithOrientation:(UIImageOrientation)orientation
{
    const CGFloat scale = [[UIScreen mainScreen] scale];
    
    CGImageRef cgImage = CGBitmapContextCreateImage(_renderContext);
    UIImage *image = [UIImage imageWithCGImage:cgImage scale:scale orientation:orientation];
    CGImageRelease(cgImage);
    
    return image;
}

- (void)addSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    NSDate *renderStartTime = [NSDate date];
    
    CGImageRef image = [self _createImageFromSampleBuffer:sampleBuffer];
    
    const CGRect imageRect = CGRectMake(
                                        0, 0,
                                        CGImageGetWidth(image), CGImageGetHeight(image)
                                        );
    
    NSMutableArray *maskRects = [[NSMutableArray alloc] init];
    CGRect maskRect = CGRectMake(
                                 _stripeSize.width * _stripeIndex, 0,
                                 _stripeSize.width, _stripeSize.height
                                 );
    // Scan the input sample buffer across the rendered image until we can't squeeze in any more...  扫描输入样品缓冲区的渲染图像，直到我们不能再在任何其他…
    while (maskRect.origin.x < _imageSize.width) {
        
        [maskRects addObject:[NSValue valueWithCGRect:maskRect]];
        
        // Move the mask to the right
        maskRect.origin.x += _stripeSize.width * _stride;
    }
    
    // Convert maskRects NSMutableArray to something Core Graphics can use
    const int maskCount = (int)[maskRects count];
    CGRect *masks = malloc(sizeof(CGRect)*maskCount);
    
    for (int index = 0; index < maskCount; ++index) {
        masks[index] = [maskRects[index] CGRectValue];
    }
    
    // Perform the render
    CGContextSaveGState(_renderContext);
    
    CGContextClipToRects(_renderContext, masks, maskCount);
    CGContextDrawImage(_renderContext, imageRect, image);
    
    CGContextRestoreGState(_renderContext);
    
    free(masks);
    CGImageRelease(image);
    
    const NSTimeInterval renderDuration = [[NSDate date] timeIntervalSinceDate:renderStartTime];
//    NSLog(@"Render time for contributor %d: %.3f msec", _stripeIndex, renderDuration * 1e3);
    
    // Move to the next stripe, allowing wrapping
    _stripeIndex = (_stripeIndex + 1) % _stride;
}

- (void)prepareBracketsWithIndex:(NSInteger)index
{
    _bracketSettings = [NSArray array];
    switch (index) {
        case 0:
            NSLog(@"Configuring auto-exposure brackets...");
            _bracketSettings = [self _exposureBrackets];
            break;
            
        case 1:
            NSLog(@"Configuring duration/ISO brackets...");
            _bracketSettings = [self _durationISOBrackets];
            break;
    }
    
    const CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions([[self.inputCamera activeFormat] formatDescription]);
    
    _imageSize = CGSizeMake(dimensions.width, dimensions.height);
    _stride = [_bracketSettings count];
    _stripeSize = CGSizeMake(dimensions.width, dimensions.height);
    
    [self _prepareImageOfSize:CGSizeMake(dimensions.width, dimensions.height)];
}

- (void)_prepareImageOfSize:(CGSize)size
{
    const size_t bitsPerComponent = 8;
    const size_t width = (size_t)size.width;
    const size_t paddedWidth = (width + 30) & ~30;
    const size_t bytesPerPixel = 4;
    const size_t bytesPerRow = paddedWidth * bytesPerPixel;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    _renderContext = CGBitmapContextCreate(NULL, size.width, size.height, bitsPerComponent, bytesPerRow, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedFirst);
    
    CGColorSpaceRelease(colorSpace);
}

- (NSArray *)_durationISOBrackets
{
    NSMutableArray *brackets = [[NSMutableArray alloc] initWithCapacity:_maxBracketCount];
    
    // ISO and Duration are hardware dependent
    
    // Fixed bracket settings
    const int fixedBracketCount = 3;
    const float ISOValues[] = {
        50, 60, 500,
    };
    const Float64 durationSecondsValues[] = {
        0.250, 0.050, 0.005,
    };
    
    for (int index = 0; index < fixedBracketCount; index++) {
        
        // Clamp fixed settings to the device limits
        const float ISO = CLAMP(
                                ISOValues[index],
                                self.inputCamera.activeFormat.minISO,
                                self.inputCamera.activeFormat.maxISO
                                );
        
        const Float64 durationSeconds = CLAMP(
                                              durationSecondsValues[index],
                                              CMTimeGetSeconds(self.inputCamera.activeFormat.minExposureDuration),
                                              CMTimeGetSeconds(self.inputCamera.activeFormat.maxExposureDuration)
                                              );
        const CMTime duration = CMTimeMakeWithSeconds(durationSeconds, 1e3);
        
        // Create bracket settings
        AVCaptureManualExposureBracketedStillImageSettings *settings = [AVCaptureManualExposureBracketedStillImageSettings manualExposureSettingsWithExposureDuration:duration ISO:ISO];
        [brackets addObject:settings];
    }
    
    return brackets;
}

- (NSArray *)_exposureBrackets
{
    NSMutableArray *brackets = [[NSMutableArray alloc] initWithCapacity:_maxBracketCount];
    
    // Fixed bracket settings
    const int fixedBracketCount = 3;
    const float biasValues[] = {
        -0.5, 0.0, +0.5,
    };
    for (int index = 0; index < fixedBracketCount; index++) {
        
        const float biasValue = biasValues[index];
        
        AVCaptureAutoExposureBracketedStillImageSettings *settings = [AVCaptureAutoExposureBracketedStillImageSettings autoExposureSettingsWithExposureTargetBias:biasValue];
        [brackets addObject:settings];
    }
    
    return brackets;
}

- (CGImageRef)_createImageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    CGImageRef image = NULL;
    
    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
    const FourCharCode subType = CMFormatDescriptionGetMediaSubType(formatDescription);
    
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    
    if (blockBuffer) {
        
        NSAssert(subType == kCMVideoCodecType_JPEG, @"Block buffer must be JPEG encoded.");
        
        // Sample buffer is a JPEG compressed image
        size_t lengthAtOffset;
        size_t length;
        char *jpegBytes;
        
        if ( (CMBlockBufferGetDataPointer(blockBuffer, 0, &lengthAtOffset, &length, &jpegBytes) == kCMBlockBufferNoErr) &&
            (lengthAtOffset == length) ) {
            
            NSData *jpegData = [NSData dataWithBytes:jpegBytes length:length];
            CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)jpegData, NULL);
            
            NSDictionary *decodeOptions = @{
                                            (id)kCGImageSourceShouldAllowFloat: @NO,
                                            (id)kCGImageSourceShouldCache: @NO,
                                            };
            image = CGImageSourceCreateImageAtIndex(imageSource, 0, (__bridge CFDictionaryRef)decodeOptions);
            
            CFRelease(imageSource);
        }
    }
    else {
        
        NSAssert(subType == kCVPixelFormatType_32BGRA, @"Image buffer must be BGRA encoded.");
        
        // Sample buffer is a BGRA uncompressed image
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        
        CVPixelBufferLockBaseAddress(imageBuffer, 0);
        
        void *baseAddress = (void *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
        
        const size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        const size_t bitsPerComponent = 8;
        const size_t width = CVPixelBufferGetWidth(imageBuffer);
        const size_t height = CVPixelBufferGetHeight(imageBuffer);
        
        CGContextRef bitmapContext = CGBitmapContextCreate(baseAddress, width, height, bitsPerComponent, bytesPerRow, colorSpace, (CGBitmapInfo)(kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst));
        image = CGBitmapContextCreateImage(bitmapContext);
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
        
        CGContextRelease(bitmapContext);
        CGColorSpaceRelease(colorSpace);
    }
    
    return image;
}

#pragma mark -
#pragma mark Photography controls

- (void)capturePhotoAsSampleBufferWithCompletionHandler:(void (^)(CMSampleBufferRef imageSampleBuffer, NSError *error))block
{
    NSLog(@"If you want to use the method capturePhotoAsSampleBufferWithCompletionHandler:, you must comment out the line in GPUImageStillCamera.m in the method initWithSessionPreset:cameraPosition: which sets the CVPixelBufferPixelFormatTypeKey, as well as uncomment the rest of the method capturePhotoAsSampleBufferWithCompletionHandler:. However, if you do this you cannot use any of the photo capture methods to take a photo if you also supply a filter.");
    
    /*dispatch_semaphore_wait(frameRenderingSemaphore, DISPATCH_TIME_FOREVER);
    
    [photoOutput captureStillImageAsynchronouslyFromConnection:[[photoOutput connections] objectAtIndex:0] completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
        block(imageSampleBuffer, error);
    }];
     
     dispatch_semaphore_signal(frameRenderingSemaphore);

     */
    
    return;
}

- (void)capturePhotoAsImageProcessedUpToFilter:(GPUImageOutput<GPUImageInput> *)finalFilterInChain withCompletionHandler:(void (^)(UIImage *processedImage, NSError *error))block;
{
    [self capturePhotoProcessedUpToFilter:finalFilterInChain withImageOnGPUHandler:^(NSError *error) {
        UIImage *filteredPhoto = nil;

        if(!error){
            filteredPhoto = [finalFilterInChain imageFromCurrentFramebuffer];
        }
        dispatch_semaphore_signal(frameRenderingSemaphore);

        block(filteredPhoto, error);
    }];
}

- (void)capturePhotoAsImageProcessedUpToFilter:(GPUImageOutput<GPUImageInput> *)finalFilterInChain withOrientation:(UIImageOrientation)orientation withCompletionHandler:(void (^)(UIImage *processedImage, NSError *error))block {

    [photoOutput setOutputSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    
    [self capturePhotoProcessedUpToFilter:finalFilterInChain withImageOnGPUHandler:^(NSError *error) {
        UIImage *filteredPhoto = nil;
        
        if(!error) {
            filteredPhoto = [finalFilterInChain imageFromCurrentFramebufferWithOrientation:orientation];
        }
        dispatch_semaphore_signal(frameRenderingSemaphore);
        
        block(filteredPhoto, error);
    }];
}

- (void)capturePhotoAsJPEGProcessedUpToFilter:(GPUImageOutput<GPUImageInput> *)finalFilterInChain withCompletionHandler:(void (^)(NSData *processedJPEG, NSError *error))block;
{
//    reportAvailableMemoryForGPUImage(@"Before Capture");

    [self capturePhotoProcessedUpToFilter:finalFilterInChain withImageOnGPUHandler:^(NSError *error) {
        NSData *dataForJPEGFile = nil;

        if(!error){
            @autoreleasepool {
                UIImage *filteredPhoto = [finalFilterInChain imageFromCurrentFramebuffer];
                dispatch_semaphore_signal(frameRenderingSemaphore);
//                reportAvailableMemoryForGPUImage(@"After UIImage generation");

                dataForJPEGFile = UIImageJPEGRepresentation(filteredPhoto,self.jpegCompressionQuality);
//                reportAvailableMemoryForGPUImage(@"After JPEG generation");
            }

//            reportAvailableMemoryForGPUImage(@"After autorelease pool");
        }else{
            dispatch_semaphore_signal(frameRenderingSemaphore);
        }

        block(dataForJPEGFile, error);
    }];
}

- (void)capturePhotoAsJPEGProcessedUpToFilter:(GPUImageOutput<GPUImageInput> *)finalFilterInChain withOrientation:(UIImageOrientation)orientation withCompletionHandler:(void (^)(NSData *processedImage, NSError *error))block {
    [self capturePhotoProcessedUpToFilter:finalFilterInChain withImageOnGPUHandler:^(NSError *error) {
        NSData *dataForJPEGFile = nil;
        
        if(!error) {
            @autoreleasepool {
                UIImage *filteredPhoto = [finalFilterInChain imageFromCurrentFramebufferWithOrientation:orientation];
                dispatch_semaphore_signal(frameRenderingSemaphore);
                
                dataForJPEGFile = UIImageJPEGRepresentation(filteredPhoto, self.jpegCompressionQuality);
            }
        } else {
            dispatch_semaphore_signal(frameRenderingSemaphore);
        }
        
        block(dataForJPEGFile, error);
    }];
}

- (void)capturePhotoAsPNGProcessedUpToFilter:(GPUImageOutput<GPUImageInput> *)finalFilterInChain withCompletionHandler:(void (^)(NSData *processedPNG, NSError *error))block;
{

    [self capturePhotoProcessedUpToFilter:finalFilterInChain withImageOnGPUHandler:^(NSError *error) {
        NSData *dataForPNGFile = nil;

        if(!error){
            @autoreleasepool {
                UIImage *filteredPhoto = [finalFilterInChain imageFromCurrentFramebuffer];
                dispatch_semaphore_signal(frameRenderingSemaphore);
                dataForPNGFile = UIImagePNGRepresentation(filteredPhoto);
            }
        }else{
            dispatch_semaphore_signal(frameRenderingSemaphore);
        }
        
        block(dataForPNGFile, error);        
    }];
    
    return;
}

- (void)capturePhotoAsPNGProcessedUpToFilter:(GPUImageOutput<GPUImageInput> *)finalFilterInChain withOrientation:(UIImageOrientation)orientation withCompletionHandler:(void (^)(NSData *processedPNG, NSError *error))block;
{
    
    [self capturePhotoProcessedUpToFilter:finalFilterInChain withImageOnGPUHandler:^(NSError *error) {
        NSData *dataForPNGFile = nil;
        
        if(!error){
            @autoreleasepool {
                UIImage *filteredPhoto = [finalFilterInChain imageFromCurrentFramebufferWithOrientation:orientation];
                dispatch_semaphore_signal(frameRenderingSemaphore);
                dataForPNGFile = UIImagePNGRepresentation(filteredPhoto);
            }
        }else{
            dispatch_semaphore_signal(frameRenderingSemaphore);
        }
        
        block(dataForPNGFile, error);
    }];
    
    return;
}

#pragma mark - Private Methods

- (void)capturePhotoProcessedUpToFilter:(GPUImageOutput<GPUImageInput> *)finalFilterInChain withImageOnGPUHandler:(void (^)(NSError *error))block
{
//    NSLog(@"%s  -%d", __func__, __LINE__);
    dispatch_semaphore_wait(frameRenderingSemaphore, DISPATCH_TIME_FOREVER);

    if(photoOutput.isCapturingStillImage){
        block([NSError errorWithDomain:AVFoundationErrorDomain code:AVErrorMaximumStillImageCaptureRequestsExceeded userInfo:nil]);
        return;
    }
    
    static SystemSoundID soundID = 0;
    if (soundID == 0) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"photoShutter2" ofType:@"caf"];
        NSLog(@"%@", path);
        NSURL *filePath = [NSURL fileURLWithPath:path];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)filePath, &soundID);
    }
    AudioServicesPlaySystemSound(soundID);

    [photoOutput captureStillImageAsynchronouslyFromConnection:[[photoOutput connections] objectAtIndex:0] completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
        if(imageSampleBuffer == NULL){
            block(error);
            return;
        }
        
#warning 在这里对图片做处理
        
        
        // For now, resize photos to fix within the max texture size of the GPU
        CVImageBufferRef cameraFrame = CMSampleBufferGetImageBuffer(imageSampleBuffer);
        
        CGSize sizeOfPhoto = CGSizeMake(CVPixelBufferGetWidth(cameraFrame), CVPixelBufferGetHeight(cameraFrame));
        CGSize scaledImageSizeToFitOnGPU = [GPUImageContext sizeThatFitsWithinATextureForSize:sizeOfPhoto];
        if (!CGSizeEqualToSize(sizeOfPhoto, scaledImageSizeToFitOnGPU))
        {
            CMSampleBufferRef sampleBuffer = NULL;
            
            if (CVPixelBufferGetPlaneCount(cameraFrame) > 0)
            {
                NSAssert(NO, @"Error: no downsampling for YUV input in the framework yet");
            }
            else
            {
                GPUImageCreateResizedSampleBuffer(cameraFrame, scaledImageSizeToFitOnGPU, &sampleBuffer);
            }

            dispatch_semaphore_signal(frameRenderingSemaphore);
            [finalFilterInChain useNextFrameForImageCapture];
            [self captureOutput:photoOutput didOutputSampleBuffer:sampleBuffer fromConnection:[[photoOutput connections] objectAtIndex:0]];
            dispatch_semaphore_wait(frameRenderingSemaphore, DISPATCH_TIME_FOREVER);
            if (sampleBuffer != NULL)
                CFRelease(sampleBuffer);
        }
        else
        {
            // 这是一个，有时返回拍照时用前置摄像头和使用iOS 5的纹理缓存损坏的图像的方法
            // This is a workaround for the corrupt images that are sometimes returned when taking a photo with the front camera and using the iOS 5.0 texture caches
            AVCaptureDevicePosition currentCameraPosition = [[videoInput device] position];
            if ( (currentCameraPosition != AVCaptureDevicePositionFront) || (![GPUImageContext supportsFastTextureUpload]) || !requiresFrontCameraTextureCacheCorruptionWorkaround)
            {
                dispatch_semaphore_signal(frameRenderingSemaphore);
                [finalFilterInChain useNextFrameForImageCapture];
                [self captureOutput:photoOutput didOutputSampleBuffer:imageSampleBuffer fromConnection:[[photoOutput connections] objectAtIndex:0]];
                dispatch_semaphore_wait(frameRenderingSemaphore, DISPATCH_TIME_FOREVER);
            }
        }
        
        CFDictionaryRef metadata = CMCopyDictionaryOfAttachments(NULL, imageSampleBuffer, kCMAttachmentMode_ShouldPropagate);
        _currentCaptureMetadata = (__bridge_transfer NSDictionary *)metadata;

        block(nil);

        _currentCaptureMetadata = nil;
    }];
}

- (void)dealloc
{
    if (_renderContext) {
        CGContextRelease(_renderContext);
    }
}

@end

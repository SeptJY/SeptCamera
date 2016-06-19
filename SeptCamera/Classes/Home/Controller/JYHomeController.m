//
//  ViewController.m
//  SeptCamera
//
//  Created by Sept on 16/5/17.
//  Copyright © 2016年 九月. All rights reserved.
//

#import "JYHomeController.h"

//#import "JYCameraManager.h"
#import "DWBubbleMenuButton.h"
#import "JYLeftTopViewMasnory.h"
#import "JYLeftTopView.h"
#import "JYContentView.h"
#import "JYVideoCamera.h"
#import "JYRulesView.h"
#import "JYVideoView.h"
#import <MediaPlayer/MediaPlayer.h>
#import "JYCollectionView.h"
#import "TTMCaptureManager.h"
#import <AssetsLibrary/AssetsLibrary.h>

#define ScreenW [UIScreen mainScreen].bounds.size.width
#define ScreenH [UIScreen mainScreen].bounds.size.height

static void * DeviceExposureDuration = &DeviceExposureDuration;
static NSString *cellID = @"cell";

@interface JYHomeController () <DWBubbleMenuViewDelegate, JYLeftTopViewDelegate, JYVideoCameraDelegate, JYVideoViewDelegate, JYCollectionViewDelegate, TTMCaptureManagerDelegate>
{
    NSTimer *_timer;
    CMSampleBufferRef _sampleBufferRef;
}

@property (nonatomic, strong) TTMCaptureManager *captureManager;

@property (strong, nonatomic) JYCollectionView *collectionView;
@property (strong, nonatomic) JYVideoCamera *videoCamera;

@property (strong, nonatomic) UIView *subView;

//@property (strong, nonatomic) UIView *screenView;

//@property (strong, nonatomic) UIImageView *focusView;
//@property (strong, nonatomic) UIImageView *zoomView;

@property (strong, nonatomic) JYRulesView *rulesView;
@property (strong, nonatomic) JYContentView *mycontentView;
@property (strong, nonatomic) JYVideoView *videoView;

@property (assign, nonatomic) CGFloat videoFocus;
@property (strong, nonatomic) JYLeftTopView *leftTopView;

@property (strong, nonatomic) DWBubbleMenuButton *menuBtn;
@property (strong, nonatomic) UIButton *videoBtns;
@property (strong, nonatomic) UIButton *phtotBtn;
@property (strong, nonatomic) UIButton *enlargeBtn;

@property (strong, nonatomic) NSMutableArray *imgsArray;

@property (strong, nonatomic) UIImageView *imgView;

@property (strong, nonatomic) UISlider *slide;

@property (assign, nonatomic) NSInteger  num;

@property (assign, nonatomic) CGFloat focus;

@property (strong, nonatomic) UILabel *focusLabel;

@property (assign, nonatomic) CGFloat time;

@property (strong, nonatomic) UISlider *soundSlider;

@end

@implementation JYHomeController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBarHidden = YES;
    
    self.time = 1.0;
    
    [self initVideoCamera];
    
    [self addSubviews];
    
    [self setupConstraints];
    
//    self.focusView.image = [UIImage imageNamed:@"1x_focus"];
//    self.zoomView.image = [UIImage imageNamed:@"home_dz_rule_icon"];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureOnClick:)];
    
    [self.rulesView addGestureRecognizer:panGesture];
    self.imgsArray = [NSMutableArray array];
    
//    NSLog(@"%f", CMTimeGetSeconds(self.videoCamera.videoCamera.inputCamera.exposureDuration));
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.34 target:self selector:@selector(longExposure) userInfo:nil repeats:YES];
    [_timer setFireDate:[NSDate distantFuture]];
    
//    [self addObserver:self forKeyPath:@"videoFocus" options:NSKeyValueObservingOptionNew context:nil];
    
    _dispatchQueue = dispatch_queue_create("com.tapharmonic.CaptureDispatchQueue", NULL);
    
    self.videoFocus = (ScreenH - 30) * 0.5;
    
    self.focus = 0;
    
//    NSArray *imgs = @[[UIImage imageNamed:@"IMG_7706"], [UIImage imageNamed:@"IMG_7707"]];
//    
//    [self createLongExposure:imgs];
//    UIImageWriteToSavedPhotosAlbum([self createLongExposure:imgs], nil, nil, nil);
    
    
//    NSLog(@"%u", arc4random() % 4);
    [self.videoCamera.videoCamera.inputCamera addObserver:self forKeyPath:@"exposureDuration" options:NSKeyValueObservingOptionNew context:DeviceExposureDuration];
    
    self.soundSlider = [self createSlider];
}

-(CGFloat)getRandomNumber:(int)from to:(int)to
{
    return (CGFloat)(from + (arc4random() % 4));
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == DeviceExposureDuration) {   // 曝光时间
        self.time = CMTimeGetSeconds(self.videoCamera.videoCamera.inputCamera.exposureDuration);
        self.focusLabel.text = [NSString stringWithFormat:@"%f", self.time];
//        _timer = [NSTimer scheduledTimerWithTimeInterval:self.time target:self selector:@selector(longExposure) userInfo:nil repeats:YES];
//        [_timer setFireDate:[NSDate distantFuture]];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)addSubviews
{
    [self.view addSubview:self.subView];
    [self.subView addSubview:self.rulesView];
    [self.subView addSubview:self.menuBtn];
    [self.subView addSubview:self.videoView];
    [self.subView addSubview:self.slide];
    [self.subView addSubview:self.mycontentView];
}

- (void)initVideoCamera
{
    self.videoCamera = [[JYVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1920x1080 superView:self.view];
    [self.videoCamera flashModel:AVCaptureFlashModeOff];
    //        [self.bottomPreview addSubview:_videoCamera.subPreview];
    [self.videoCamera cameraManagerChangeFoucus:1.2];
//    [self.videoCamera setExposureDurationWith:0.1];
//    [self.videoCamera cameraManagerExposureIOS:46];
//    [self.videoCamera prepareHDRWithIndex:1];
//    self.videoCamera.frameRate = 60;
//    [self.videoCamera cameraManagerEffectqualityWithTag:61 withBlock:nil];
//    [self.videoCamera aswitchFormatWithDesiredFPS:240];
    
    self.videoCamera.delegate = self;
}

- (UIView *)subView
{
    if (!_subView) {
        
        _subView = [[UIView alloc] init];
        
        [self.view addSubview:_subView];
    }
    return _subView;
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



// =============================================================================
#pragma mark - AVCaptureManagerDeleagte

- (void)didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL error:(NSError *)error {
    
    LOG_CURRENT_METHOD;
    
    if (error) {
        NSLog(@"error:%@", error);
        return;
    }
    
    [self saveRecordedFile:outputFileURL];
}

- (JYRulesView *)rulesView
{
    if (!_rulesView) {
        
        _rulesView = [JYRulesView rulesView];
        _rulesView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
    }
    return _rulesView;
}

- (JYVideoView *)videoView
{
    if (!_videoView) {
        
        _videoView = [JYVideoView videoView];
        _videoView.delegate = self;
    }
    return _videoView;
}

- (JYContentView *)mycontentView
{
    if (!_mycontentView) {
        _mycontentView = [[JYContentView alloc] init];
        _mycontentView.hidden = YES;
        _mycontentView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
    }
    return _mycontentView;
}

- (UILabel *)focusLabel
{
    if (!_focusLabel) {
        
        _focusLabel = [[UILabel alloc] init];
        
        _focusLabel.textColor = [UIColor yellowColor];
        _focusLabel.textAlignment = NSTextAlignmentCenter;
        
        [self.subView addSubview:_focusLabel];
    }
    return _focusLabel;
}

- (JYCollectionView *)collectionView
{
    if (!_collectionView) {
        
        _collectionView = [JYCollectionView collectionViewWithSize:CGSizeMake(300, 40)];
        
        _collectionView.backgroundColor= [[UIColor blackColor] colorWithAlphaComponent:0.3];
        _collectionView.delegate = self;
        _collectionView.hidden = YES;
        
        [self.subView addSubview:_collectionView];
    }
    return _collectionView;
}

- (void)collectionViewDidSelectIndex:(NSInteger)index
{
    
}

#pragma mark -------------------------> JYVideoViewDelegate
- (void)videoViewBtnOnClick:(UIButton *)btn
{
    switch (btn.tag) {
        case 20:
            btn.selected = !btn.selected;
            if (btn.selected == 1) {
                
//                [self.captureManager testStart];
                [self.videoCamera startVideo];
//                [self.videoCamera prepareHDRWithIndex:1];
                [_timer setFireDate:[NSDate date]];
//                [self.soundSlider setValue:0.0f animated:NO];
//                [self.soundSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
            } else {
//                [self.videoCamera bbbbbbbbbbb];
//                [self.captureManager testStop];
                [self.videoCamera stopVideo];
//                [self.videoCamera prepareHDRWithIndex:0];
//                [self.soundSlider setValue:0.8f animated:NO];
//                [self.soundSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
                [_timer setFireDate:[NSDate distantFuture]];
//                NSLog(@"%@", self.videoCamera.imgsArray);
//                UIImageWriteToSavedPhotosAlbum([self createLongExposure:self.videoCamera.imgsArray], nil, nil, nil);
//                [self.videoCamera.imgsArray removeAllObjects];
            }
            break;
        case 21:
            
            break;
        case 22:
        {
            [self.videoCamera takePhoto];
//            [self.videoCamera takePhotosWithHDR];
//            [self.videoCamera takePhotoWithArray];
//            self.num = 5;
//            NSLog(@"%@", _sampleBufferRef);
//            UIImage *image = [self imageFromSampleBuffer:_sampleBufferRef];
//            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
            
//            [_timer setFireDate:[NSDate date]];
//            [self.videoCamera takePhotosWithHDR];
//            NSLog(@"%f", self.focus);
//            [self performSelector:@selector(stop) withObject:nil afterDelay:self.focus / (screenH - 30) * 3 + 1];
        }
            break;
            
        default:
            break;
    }
}

- (UISlider *)createSlider
{
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    volumeView.hidden = NO;
    volumeView.frame = CGRectMake(-1000, -1000, 100, 100);
    
    [self.subView addSubview:volumeView];
    UISlider* volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            volumeViewSlider = (UISlider*)view;
            break;
        }
    }
    return volumeViewSlider;
}

- (void)stop
{
    [_timer setFireDate:[NSDate distantFuture]];
    NSLog(@"%@", self.videoCamera.imgsArray);
    UIImageWriteToSavedPhotosAlbum([self createLongExposure:self.videoCamera.imgsArray], nil, nil, nil);
    [self.videoCamera.imgsArray removeAllObjects];
}

- (UISlider *)slide
{
    if (!_slide) {
        
        _slide = [[UISlider alloc] init];
        
        _slide.value = 0.5;
        _slide.minimumValue = 0;
        _slide.maximumValue = 1;
//        _slide.hidden = YES;
        
        [_slide addTarget:self action:@selector(slideValueChange:) forControlEvents:UIControlEventValueChanged];
    }
    return _slide;
}

- (void)slideValueChange:(UISlider *)slide
{
    [self.videoCamera setExposureDurationWith:slide.value];
    NSLog(@"%f", slide.value);
//    [self.videoCamera.saturationFilter setSaturation:slide.value];
//    NSLog(@"%f", CMTimeGetSeconds(self.videoCamera.videoCamera.inputCamera.exposureDuration));
//    self.focusLabel.text = [NSString stringWithFormat:@"%f", CMTimeGetSeconds(self.videoCamera.videoCamera.inputCamera.exposureDuration)];
}

- (void)panGestureOnClick:(UIPanGestureRecognizer *)panGesture
{
    if (panGesture.state == UIGestureRecognizerStateChanged || panGesture.state == UIGestureRecognizerStateEnded) {
        
        CGPoint translation = [panGesture translationInView:self.rulesView];
        self.focus += translation.y;
        if (self.focus <= 0.0) {
            self.focus = 0;
        } else if (self.focus >= (screenH - 30))
        {
            self.focus = screenH - 30;
        }
        
        [self.rulesView animationWith:self.focus index:0];
        
        [panGesture setTranslation:CGPointMake(0, 0) inView:self.rulesView];
    }
}

- (void)longExposure
{
//    UIImage *image = [UIImage imageFromSampleBuffer:_sampleBufferRef];
//    NSLog(@"%@", image);
    
//    [self.imgsArray addObject:image];
//    [self.videoCamera takePhotoWithArray];
    self.time += 0.02;
//    if (self.time >= 4.0) {
//        self.time -= 0.2;
//    } else if (self.time >= 0.0 && self.)
    [self.videoCamera cameraManagerVideoZoom:self.time];
//    NSLog(@"%u", arc4random() % 4);
}

- (void)cameraManageTakingPhotoSucuess:(UIImage *)image
{
//    self.num++;
//    NSLog(@"%lu -- %@", (unsigned long)self.imgsArray.count, image);
//    if (image) {
//        [self.imgsArray addObject:image];
//    }
////    if (self.num <= 6) {
////        [self.videoCamera takePhoto];
////    } else {
//    
//        self.imgView.image = [self createLongExposure:self.imgsArray];
////    }
//    if (self.imgsArray.count > 5) {
//        UIImageWriteToSavedPhotosAlbum(self.imgView.image, nil, nil, nil);
//    }
//    if (self.num <= 6) {
//        [self.videoCamera takePhotoWithArray];
//    } else {
//        UIImageWriteToSavedPhotosAlbum([self createLongExposure:self.videoCamera.imgsArray], nil, nil, nil);
//        self.num = 0;
////        NSLog(@"%@", self.videoCamera.imgsArray);
//    }
//    NSLog(@"aaaa");
}

- (UIImage *) createLongExposure:(NSArray *)images {
    UIImage *firstImg = images[0];
    CGSize imgSize = firstImg.size;
    CGFloat alpha = 1.0 / images.count;
    
    UIGraphicsBeginImageContext(imgSize);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [[UIColor blackColor] CGColor]);
    CGContextFillRect(context, CGRectMake(0, 0, imgSize.width, imgSize.height));
    
    for (UIImage *image in images) {
        [image drawInRect:CGRectMake(0, 0, imgSize.width, imgSize.height)
                blendMode:kCGBlendModePlusLighter alpha:alpha];
    }
    UIImage *longExpImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return longExpImg;
}

- (UIImageView *)imgView
{
    if (!_imgView) {
        
        _imgView = [[UIImageView alloc] init];
        
        _imgView.backgroundColor = [UIColor clearColor];
        _imgView.alpha = 0.8;
        
        [self.view insertSubview:_imgView belowSubview:self.subView];
    }
    return _imgView;
}

/** 左上角设置按钮和快捷键按钮 */
- (JYLeftTopView *)leftTopView
{
    if (!_leftTopView) {
        
        _leftTopView = [[JYLeftTopView alloc] init];
        _leftTopView.backgroundColor = [UIColor clearColor];
        _leftTopView.delegate = self;
        
        [self.subView addSubview:_leftTopView];
    }
    return _leftTopView;
}

//#pragma mark -------------------------> JYLeftTopViewDelegate
- (void)leftTopViewQuickOrSettingBtnOnClick:(UIButton *)btn
{
    self.mycontentView.hidden = !btn.selected;
//    if (btn.selected == 1) {
//        [self.videoCamera aaaaaaaaa];
//        for (UIView *subView in self.view.subviews) {
//            if ([[subView class] isSubclassOfClass:[GPUImageView class]]) {
//                subView.hidden = YES;
//            }
//        }
//        NSLog(@"%@", self.view.layer.sublayers);
//        self.captureManager = [[TTMCaptureManager alloc] initWithPreviewView:self.view
//                                                         preferredCameraType:CameraTypeBack
//                                                                  outputMode:OutputModeVideoData];
//        self.captureManager.delegate = self;
//        
//        [self.captureManager switchFormatWithDesiredFPS:120];
//    } else{
//        [self.captureManager stopCapature];
//        self.captureManager = nil;
//
//        for (CALayer *layer in self.view.layer.sublayers) {
//            if ([[layer class] isSubclassOfClass:[AVCaptureVideoPreviewLayer class]]) {
//                layer.hidden = YES;
//            }
//        }
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            for (UIView *subView in self.view.subviews) {
//                if ([[subView class] isSubclassOfClass:[GPUImageView class]]) {
//                    subView.hidden = NO;
//                }
//            }
////            NSLog(@"%@", self.view.subviews);
////
//            [self.videoCamera bbbbbbbbbbb];
//        });
//    }
    
}

- (DWBubbleMenuButton *)menuBtn
{
    if (!_menuBtn) {
        _menuBtn = [[DWBubbleMenuButton alloc] initWithFrame:CGRectMake(18.f, 10.f, 36, 36) expansionDirection:DirectionDown];
        
        _menuBtn.delegate = self;
        
        _menuBtn.homeButtonView = self.leftTopView.quickBtn;
        
        [_menuBtn addButtons:[self createDemoButtonArray]];
    }
    return _menuBtn;
}

- (NSArray *)createDemoButtonArray
{
    NSMutableArray *buttonsMutable = [[NSMutableArray alloc] init];
    
    //    [buttonsMutable addObject:self.mainBtn];
    [buttonsMutable addObject:self.videoBtns];
    [buttonsMutable addObject:self.phtotBtn];
    [buttonsMutable addObject:self.enlargeBtn];
    
    return [buttonsMutable copy];
}

#pragma mark -------------------------> DWBubbleMenuViewDelegate
/** 按钮显示之后 */
- (void)bubbleMenuButtonWillExpand:(DWBubbleMenuButton *)expandableView
{
//        NSLog(@"%s", __func__);
//    self.leftTopView.isShow = YES;
    self.leftTopView.quickBtn.image = [UIImage imageNamed:@"dub_arrow_up"];
}

/** 按钮掩藏之后 */
- (void)bubbleMenuButtonDidCollapse:(DWBubbleMenuButton *)expandableView
{
//        NSLog(@"%s", __func__);
//    self.leftTopView.isShow = NO;
    self.leftTopView.quickBtn.image = [UIImage imageNamed:@"dub_arrow_down"];
}

- (UIButton *)videoBtns
{
    if (!_videoBtns) {
        
        _videoBtns = [self createBtnWithImg:@"shift_ZMtoMF" seletedImg:@"shift_MFtoZM" size:CGSizeMake(35.0f, 65.0f)];
        _videoBtns.tag = 100;
        _videoBtns.selected = YES;
    }
    return _videoBtns;
}

- (UIButton *)phtotBtn
{
    if (!_phtotBtn) {
        
        _phtotBtn = [self createBtnWithImg:@"shift_RECtoCAM" seletedImg:@"shift_CAMtoREC" size:CGSizeMake(35.0f, 65.0f)];
        _phtotBtn.tag = 101;
    }
    return _phtotBtn;
}

- (UIButton *)enlargeBtn
{
    if (!_enlargeBtn) {
        
        _enlargeBtn = [self createBtnWithImg:@"Zoom_in_on" seletedImg:@"Zoom_in_off" size:CGSizeMake(35.0f, 60.0f)];
        _enlargeBtn.tag = 102;
        _enlargeBtn.imageEdgeInsets = UIEdgeInsetsMake(12.5, 0, 12.5, 0);
    }
    return _enlargeBtn;
}

- (UIButton *)createBtnWithImg:(NSString *)img seletedImg:(NSString *)sImg  size:(CGSize)size
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [button setImage:[UIImage imageNamed:img] forState:UIControlStateSelected];
    [button setImage:[UIImage imageNamed:sImg] forState:UIControlStateNormal];
    [button setAdjustsImageWhenHighlighted:NO];
    
    button.frame = CGRectMake(0.f, 0.f, size.width, size.height);
    button.clipsToBounds = YES;
    
    [button addTarget:self action:@selector(plusButtonOnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

- (void)plusButtonOnClick:(UIButton *)btn
{
    
}

//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
//{
//    if ([keyPath isEqualToString:@"videoFocus"]) {
//        [self animationWith:self.videoFocus layer:self.focusView.layer];
//    } else {
//        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
//    }
//}

#pragma mark -------------------------> 相机操作
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.videoCamera startCamera];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.videoCamera stopCamera];
}



#pragma mark -------------------------> JYVideoCameraDelegate
- (void)videoCameraDidOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
//    NSLog(@"aaaa");
    _sampleBufferRef = sampleBuffer;
}

///** 刻度尺图片View */
//- (UIImageView *)focusView
//{
//    if (!_focusView) {
//        
//        _focusView = [[UIImageView alloc] init];
//        
//        [self.ruleBottomView  addSubview:_focusView];
//        
//        [_focusView mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.top.equalTo(self.ruleBottomView).offset(0);
//            make.bottom.equalTo(self.ruleBottomView).offset(0);
//            make.left.equalTo(self.ruleBottomView).offset(0);
//            make.right.equalTo(self.ruleBottomView).offset(0);
//        }];
//    }
//    return _focusView;
//}
//
//- (UIImageView *)zoomView
//{
//    if (!_zoomView) {
//        
//        _zoomView = [[UIImageView alloc] init];
//        
//        _zoomView.hidden = YES;
//        [self.ruleBottomView  addSubview:_zoomView];
//        
//        [_zoomView mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.top.equalTo(self.ruleBottomView).offset(0);
//            make.bottom.equalTo(self.ruleBottomView).offset(0);
//            make.left.equalTo(self.ruleBottomView).offset(0);
//            make.right.equalTo(self.ruleBottomView).offset(0);
//        }];
//    }
//    return _zoomView;
//}

//- (void)panGestureOnClick:(UIPanGestureRecognizer *)panGesture
//{
//    if (panGesture.state == UIGestureRecognizerStateChanged || panGesture.state == UIGestureRecognizerStateEnded) {
//        
//        CGPoint translation = [panGesture translationInView:self.ruleBottomView];
//        
//        self.videoFocus += translation.y;
//        
//        [panGesture setTranslation:CGPointMake(0, 0) inView:self.ruleBottomView];
//    }
//}
//
//- (void)ruleImgViewTimer
//{
//    [self animationWith:self.videoFocus layer:self.focusView.layer];
//}

- (void)animationWith:(CGFloat)value layer:(CALayer *)layer
{
    if (value <= 0) value = 0;
    if (value >= (ScreenH - 30)) value = ScreenH - 30;
    
    CABasicAnimation *anima=[CABasicAnimation animation];
    
    //1.1告诉系统要执行什么样的动画
    anima.keyPath=@"position";
    //设置通过动画，将layer从哪儿移动到哪儿
    anima.toValue = [NSValue valueWithCGPoint:CGPointMake(25, value + 15)];
    //    NSLog(@"%@", anima.toValue);
    
    //1.2设置动画执行完毕之后不删除动画
    anima.removedOnCompletion=NO;
    //1.3设置保存动画的最新状态
    anima.fillMode=kCAFillModeForwards;
    //2.添加核心动画到layer
    [layer addAnimation:anima forKey:nil];
}

- (IBAction)videoCameraOnClick:(UIButton *)sender
{
//    sender.selected = !sender.selected;
//    if (sender.selected == 1) {
//        [self.videoCamera startVideo];
        [_timer setFireDate:[NSDate date]];
//    } else {
////        [self.videoCamera stopVideo];
//        [_timer setFireDate:[NSDate distantFuture]];
//        
//        
//        UIImageWriteToSavedPhotosAlbum([self createLongExposure:self.imgsArray], nil, nil, nil);
//        self.imgView.image = nil;
//    }
//    [self.videoCamera takePhoto];
    
    
}
- (IBAction)takePhotoOnClick:(UIButton *)sender {
}
- (IBAction)iconsChooseOnClick:(UIButton *)sender {
}

- (void)setupConstraints
{
    __weak JYHomeController *weakSelf = self;
    [self.subView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.view);
        make.leading.equalTo(weakSelf.view);
        make.bottom.equalTo(weakSelf.view);
        make.trailing.equalTo(weakSelf.view);
    }];
    
    [self.imgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.bottom.trailing.mas_equalTo(weakSelf.subView);
    }];
    
    [self.rulesView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.trailing.bottom.equalTo(weakSelf.subView);
        make.width.mas_equalTo(50);
    }];
    
    [self.videoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(weakSelf.subView);
        make.right.mas_equalTo(weakSelf.rulesView.mas_left).offset(0);
        make.width.mas_equalTo(60);
    }];
    
    [self.slide mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(weakSelf.view).offset(-20);
        make.right.mas_equalTo(weakSelf.videoView.mas_left).offset(-10);
        make.left.equalTo(weakSelf.view).offset(10);
    }];
    
    [self.mycontentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(weakSelf.view).offset(-20);
        make.leading.equalTo(weakSelf.view).offset(70);
        make.right.mas_equalTo(weakSelf.videoView.mas_left).offset(-20);
        make.top.equalTo(weakSelf.view).offset(65);
        
    }];
    
    [self.focusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(weakSelf.slide);
        make.bottom.mas_equalTo(weakSelf.slide.mas_top).offset(-15);
    }];
    
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(weakSelf.view).offset(70);
        make.bottom.equalTo(weakSelf.view).offset(-20);
        make.height.mas_equalTo(40);
        make.right.mas_equalTo(weakSelf.videoView.mas_left).offset(-20);
    }];
}

- (void)viewWillLayoutSubviews
{
    // 5.左上角的View  -- 设置和快捷键
    self.leftTopView.frame = CGRectMake(0, 0, 120, 55);
}

@end

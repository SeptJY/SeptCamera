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

#define ScreenW [UIScreen mainScreen].bounds.size.width
#define ScreenH [UIScreen mainScreen].bounds.size.height

@interface JYHomeController () <DWBubbleMenuViewDelegate, JYLeftTopViewDelegate, JYVideoCameraDelegate>
{
    NSTimer *_timer;
    CMSampleBufferRef _sampleBufferRef;
}

@property (strong, nonatomic) JYVideoCamera *videoCamera;

@property (strong, nonatomic) UIView *subView;

//@property (strong, nonatomic) UIView *screenView;

//@property (strong, nonatomic) UIImageView *focusView;
//@property (strong, nonatomic) UIImageView *zoomView;

//@property (strong, nonatomic) UIView *ruleBottomView;
//@property (strong, nonatomic) JYContentView *contentView;

@property (assign, nonatomic) CGFloat videoFocus;
@property (strong, nonatomic) JYLeftTopView *leftTopView;

@property (strong, nonatomic) DWBubbleMenuButton *menuBtn;
@property (strong, nonatomic) UIButton *videoBtns;
@property (strong, nonatomic) UIButton *phtotBtn;
@property (strong, nonatomic) UIButton *enlargeBtn;

@property (strong, nonatomic) NSMutableArray *imgsArray;

@property (strong, nonatomic) UIImageView *imgView;

@end

@implementation JYHomeController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBarHidden = YES;
    
    [self initVideoCamera];
    
    [self addSubviews];
    
    [self setupConstraints];
    
//    self.focusView.image = [UIImage imageNamed:@"1x_focus"];
//    self.zoomView.image = [UIImage imageNamed:@"home_dz_rule_icon"];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureOnClick:)];
    
//    [self.ruleBottomView addGestureRecognizer:panGesture];
    self.imgsArray = [NSMutableArray array];
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:1000.0/1000 target:self selector:@selector(longExposure) userInfo:nil repeats:YES];
    [_timer setFireDate:[NSDate distantFuture]];
    
//    [self addObserver:self forKeyPath:@"videoFocus" options:NSKeyValueObservingOptionNew context:nil];
    
    _dispatchQueue = dispatch_queue_create("com.tapharmonic.CaptureDispatchQueue", NULL);
    
    self.videoFocus = (ScreenH - 30) * 0.5;
    
    
    
//    NSArray *imgs = @[[UIImage imageNamed:@"IMG_7706"], [UIImage imageNamed:@"IMG_7707"]];
//    
//    [self createLongExposure:imgs];
//    UIImageWriteToSavedPhotosAlbum([self createLongExposure:imgs], nil, nil, nil);
    
    
    
    
}

- (void)addSubviews
{
    [self.view addSubview:self.subView];
    
    [self.subView addSubview:self.menuBtn];
}

- (void)initVideoCamera
{
    self.videoCamera = [[JYVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1920x1080 superView:self.view];
    [self.videoCamera flashModel:AVCaptureFlashModeAuto];
    //        [self.bottomPreview addSubview:_videoCamera.subPreview];
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

- (void)longExposure
{
//    UIImage *image = [UIImage imageFromSampleBuffer:_sampleBufferRef];
//    NSLog(@"%@", image);
    
//    [self.imgsArray addObject:image];
    [self.videoCamera takePhoto];
}

- (void)cameraManageTakingPhotoSucuess:(UIImage *)image
{
    [self.imgsArray addObject:image];
    self.imgView.image = [self createLongExposure:self.imgsArray];
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
        _imgView.alpha = 0.6;
        
        [self.view addSubview:_imgView];
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
//- (void)leftTopViewQuickOrSettingBtnOnClick:(UIButton *)btn
//{
//    self.contentView.hidden = !btn.selected;
//}

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

- (IBAction)chinaOnClick:(UIButton *)sender
{
    [JYLanguageTool setUserlanguage:@"zh-Hans"];
    
    //改变完成之后发送通知，告诉其他页面修改完成，提示刷新界面
    [[NSNotificationCenter defaultCenter] postNotificationName:@"changeLanguage" object:nil];
}

- (IBAction)englishOnClick:(UIButton *)sender
{
    [JYLanguageTool setUserlanguage:@"en"];
    
    //改变完成之后发送通知，告诉其他页面修改完成，提示刷新界面
    [[NSNotificationCenter defaultCenter] postNotificationName:@"changeLanguage" object:nil];
}

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
    sender.selected = !sender.selected;
    if (sender.selected == 1) {
//        [self.videoCamera startVideo];
        [_timer setFireDate:[NSDate date]];
    } else {
//        [self.videoCamera stopVideo];
        [_timer setFireDate:[NSDate distantFuture]];
        
        
        UIImageWriteToSavedPhotosAlbum([self createLongExposure:self.imgsArray], nil, nil, nil);
        self.imgView.image = nil;
    }
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
}

- (void)viewWillLayoutSubviews
{
    // 5.左上角的View  -- 设置和快捷键
    self.leftTopView.frame = CGRectMake(0, 0, 120, 55);
}

@end

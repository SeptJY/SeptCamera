//
//  ViewController.m
//  SeptCamera
//
//  Created by Sept on 16/5/17.
//  Copyright © 2016年 九月. All rights reserved.
//

#import "JYHomeController.h"

#import "JYCameraManager.h"
#import "Masonry.h"

#define ScreenW [UIScreen mainScreen].bounds.size.width
#define ScreenH [UIScreen mainScreen].bounds.size.height

@interface JYHomeController ()

@property (strong, nonatomic) JYCameraManager *videoCamera;

@property (weak, nonatomic) IBOutlet UIView *subView;

@property (weak, nonatomic) IBOutlet UIView *screenView;

@property (strong, nonatomic) UIImageView *focusView;
@property (strong, nonatomic) UIImageView *zoomView;

@property (weak, nonatomic) IBOutlet UIView *ruleBottomView;

@property (assign, nonatomic) CGFloat videoFocus;

@property (weak, nonatomic) IBOutlet UIButton *videoBtn;
@property (weak, nonatomic) IBOutlet UIButton *photoBtn;
@property (weak, nonatomic) IBOutlet UIButton *iconsBtn;
@end

@implementation JYHomeController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBarHidden = YES;
    
    self.focusView.image = [UIImage imageNamed:@"1x_focus"];
    self.zoomView.image = [UIImage imageNamed:@"home_dz_rule_icon"];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureOnClick:)];
    
    [self.ruleBottomView addGestureRecognizer:panGesture];
    
//    [NSTimer scheduledTimerWithTimeInterval:20.0/1000 target:self selector:@selector(ruleImgViewTimer) userInfo:nil repeats:YES];
    
    [self addObserver:self forKeyPath:@"videoFocus" options:NSKeyValueObservingOptionNew context:nil];
    
    _dispatchQueue = dispatch_queue_create("com.tapharmonic.CaptureDispatchQueue", NULL);
    
    self.videoFocus = (ScreenH - 30) * 0.5;
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"videoFocus"]) {
        [self animationWith:self.videoFocus layer:self.focusView.layer];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
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

- (JYCameraManager *)videoCamera {
    if (!_videoCamera) {
        _videoCamera = [[JYCameraManager alloc] initWithFrame:self.view.bounds superview:self.subView];
        //        _videoCamera.cameraDelegate = self;
        [_videoCamera flashModel:AVCaptureFlashModeAuto];
        //        [self.bottomPreview addSubview:_videoCamera.subPreview];
    }
    return _videoCamera;
}

/** 刻度尺图片View */
- (UIImageView *)focusView
{
    if (!_focusView) {
        
        _focusView = [[UIImageView alloc] init];
        
        [self.ruleBottomView  addSubview:_focusView];
        
        [_focusView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.ruleBottomView).offset(0);
            make.bottom.equalTo(self.ruleBottomView).offset(0);
            make.left.equalTo(self.ruleBottomView).offset(0);
            make.right.equalTo(self.ruleBottomView).offset(0);
        }];
    }
    return _focusView;
}

- (UIImageView *)zoomView
{
    if (!_zoomView) {
        
        _zoomView = [[UIImageView alloc] init];
        
        _zoomView.hidden = YES;
        [self.ruleBottomView  addSubview:_zoomView];
        
        [_zoomView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.ruleBottomView).offset(0);
            make.bottom.equalTo(self.ruleBottomView).offset(0);
            make.left.equalTo(self.ruleBottomView).offset(0);
            make.right.equalTo(self.ruleBottomView).offset(0);
        }];
    }
    return _zoomView;
}

- (void)panGestureOnClick:(UIPanGestureRecognizer *)panGesture
{
    if (panGesture.state == UIGestureRecognizerStateChanged || panGesture.state == UIGestureRecognizerStateEnded) {
        
        CGPoint translation = [panGesture translationInView:self.ruleBottomView];
        
        self.videoFocus += translation.y;
        
        [panGesture setTranslation:CGPointMake(0, 0) inView:self.ruleBottomView];
    }
}

- (void)ruleImgViewTimer
{
    [self animationWith:self.videoFocus layer:self.focusView.layer];
}

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

- (IBAction)videoCameraOnClick:(UIButton *)sender {
}
- (IBAction)takePhotoOnClick:(UIButton *)sender {
}
- (IBAction)iconsChooseOnClick:(UIButton *)sender {
}

- (void)viewWillLayoutSubviews
{
    
}

@end

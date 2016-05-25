//
//  JYLeftTopView.m
//  SeptWeiYing
//
//  Created by Sept on 16/3/9.
//  Copyright © 2016年 九月. All rights reserved.
//

// 左上角快捷键和设置按钮

#import "JYLeftTopView.h"

#import <objc/runtime.h>

@interface JYLeftTopView()
{
    NSTimer *_timer;
}

@property (strong, nonatomic) UIView *lineView;

@property (strong, nonatomic) UIView *bgView;


@property (strong, nonatomic) UIButton *settingBtn;

@property (strong, nonatomic) UIImageView *iRlectricityView;

@property (strong, nonatomic) UIView *showView;

@end

@implementation JYLeftTopView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        self.layer.opacity = ([[NSUserDefaults standardUserDefaults] floatForKey:@"opacity"] == 0) ? 1 : [[NSUserDefaults standardUserDefaults] floatForKey:@"opacity"];
        
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(refreshDeviceDianliang) userInfo:nil repeats:YES];
    }
    return self;
}

- (void)refreshDeviceDianliang
{
    [self getCurrentBatteryLevel];
}

- (UIImageView *)quickBtn
{
    if (!_quickBtn) {
        
        _quickBtn = [[UIImageView alloc] init];
        _quickBtn.image = [UIImage imageNamed:@"dub_arrow_down"];
        
        [self addSubview:_quickBtn];
    }
    return _quickBtn;
}

- (UIButton *)settingBtn
{
    if (!_settingBtn) {
        
        _settingBtn = [[UIButton alloc] init];
        
        _settingBtn.tag = 11;
        [_settingBtn setImage:[UIImage imageNamed:@"logo_setup_off"] forState:UIControlStateNormal];
        [_settingBtn setImage:[UIImage imageNamed:@"logo_setup_on"] forState:UIControlStateSelected];
        
        [_settingBtn addTarget:self action:@selector(leftTopViewQuickOrSettingBtnOnClick:) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:_settingBtn];
    }
    return _settingBtn;
}

- (UILabel *)label
{
    if (!_label) {
        
        _label = [[UILabel alloc] init];
        _label.backgroundColor = [UIColor clearColor];
        
        [self insertSubview:_label aboveSubview:self.quickBtn];
    }
    return _label;
}
- (UIImageView *)iRlectricityView
{
    if (!_iRlectricityView) {
        
        _iRlectricityView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"batter"]];
        
        [self addSubview:_iRlectricityView];
    }
    return _iRlectricityView;
}

- (void)setSettingHiden:(BOOL)settingHiden
{
    _settingHiden = settingHiden;
    
    self.settingBtn.selected = settingHiden;
}

- (UIView *)showView
{
    if (!_showView) {
        
        _showView = [[UIView alloc] init];
        
        _showView.backgroundColor = [UIColor yellowColor];
        
        [self.iRlectricityView addSubview:_showView];
    }
    return _showView;
}

- (void)leftTopViewQuickOrSettingBtnOnClick:(UIButton *)btn
{
    btn.selected = !btn.selected;
    if (self.delegate && [self.delegate respondsToSelector:@selector(leftTopViewQuickOrSettingBtnOnClick:)]) {
        [self.delegate leftTopViewQuickOrSettingBtnOnClick:btn];
    }
}

- (UIView *)bgView
{
    if (!_bgView) {
        
        _bgView = [[UIView alloc] init];
        
        _bgView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
        
        [self addSubview:_bgView];
    }
    return _bgView;
}

- (UIView *)lineView
{
    if (!_lineView) {
        
        _lineView = [[UIView alloc] init];
        
        _lineView.backgroundColor = [UIColor yellowColor];
        
        [self.bgView addSubview:_lineView];
    }
    return _lineView;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat bgW = self.width - 2 * 10;
    CGFloat bgH = self.height - 2 * 10;
    CGFloat bgX = 10;
    CGFloat bgY = 10;
    
    self.bgView.frame = CGRectMake(bgX, bgY, bgW, bgH);
    self.bgView.layer.cornerRadius = bgH / 2;
    
    CGFloat lineW = 1;
    CGFloat lineH = 20;
    CGFloat lineX = (self.bgView.width - lineW) * 0.5;
    CGFloat lineY = (self.bgView.height - lineH) * 0.5;
    
    self.lineView.frame = CGRectMake(lineX, lineY, lineW, lineH);
    
//    self.quickBtn.frame = CGRectMake(0, 0, self.width / 2, self.height);
    
//    self.quickBtn.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);
    self.settingBtn.frame = CGRectMake(self.width / 2, 0, self.width / 2, self.height);
    self.settingBtn.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 10);
    
    self.quickBtn.frame = CGRectMake(0, 0, 35, 35);
    
    // 3.设置电量图片的frmae
    CGFloat rlectricityW = 25;
    CGFloat rlectricityH = self.iRlectricityView.image.size.height;
    CGFloat rlectricityX = self.bgView.x + self.bgView.width + 10;
    CGFloat rlectricityY = (self.height - rlectricityH) * 0.5;
    
    self.iRlectricityView.frame = CGRectMake(rlectricityX, rlectricityY, rlectricityW, rlectricityH);
    
    // 4.设置电量显示的frmae
    CGFloat showW = 0;    // 默认宽度为0
    CGFloat showH = 8;
    CGFloat showX = 2;
    CGFloat showY = 2;
    
    self.showView.frame = CGRectMake(showX, showY, showW, showH);
}

- (int)getCurrentBatteryLevel
{
    UIApplication *app = [UIApplication sharedApplication];
    
    if (app.applicationState == UIApplicationStateActive||app.applicationState==UIApplicationStateInactive) {
        Ivar ivar=  class_getInstanceVariable([app class],"_statusBar");
        id status  = object_getIvar(app, ivar);
        for (id aview in [status subviews]) {
            int batteryLevel = 0;
            for (id bview in [aview subviews]) {
                if ([NSStringFromClass([bview class]) caseInsensitiveCompare:@"UIStatusBarBatteryItemView"] == NSOrderedSame&&[[[UIDevice currentDevice] systemVersion] floatValue] >=6.0)
                {
                    
                    Ivar ivar=  class_getInstanceVariable([bview class],"_capacity");
                    if(ivar)
                    {
                        batteryLevel = ((int (*)(id, Ivar))object_getIvar)(bview, ivar);
                        //这种方式也可以
                        /*ptrdiff_t offset = ivar_getOffset(ivar);
                         unsigned char *stuffBytes = (unsigned char *)(__bridge void *)bview;
                         batteryLevel = * ((int *)(stuffBytes + offset));*/
                        self.showView.width = (CGFloat)batteryLevel/100 * 19;
                        if (batteryLevel > 0 && batteryLevel <= 100) {
                            return batteryLevel;
                            
                        } else {
                            return 0;
                        }
                    }
                    
                }
                
            }
        }
    }
    
    return 0;
}

@end

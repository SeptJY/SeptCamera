//
//  JYRulesView.m
//  SeptCamera
//
//  Created by Sept on 16/5/31.
//  Copyright © 2016年 九月. All rights reserved.
//

#import "JYRulesView.h"

@interface JYRulesView ()

@property (strong, nonatomic) UIImageView *focusView;

@property (strong, nonatomic) UIImageView *zoomView;

@property (strong, nonatomic) UIImageView *blueView;

@end

@implementation JYRulesView

+ (instancetype)rulesView
{
    return [[self alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self addSubview:self.focusView];
        [self addSubview:self.zoomView];
        [self addSubview:self.blueView];
        
        [self setupConstraints];
    }
    return self;
}

/** 刻度尺图片View */
- (UIImageView *)focusView
{
    if (!_focusView) {
        
        _focusView = [[UIImageView alloc] init];
        //设置需要显示的图片
        _focusView.image= [UIImage imageNamed:@"1x_focus"];
    }
    return _focusView;
}

- (UIImageView *)zoomView
{
    if (!_zoomView) {
        
        _zoomView = [[UIImageView alloc] init];
        //设置需要显示的图片
        _zoomView.image= [UIImage imageNamed:@"2x_focus"];
    }
    return _zoomView;
}

- (UIImageView *)blueView
{
    if (!_blueView) {
        
        _blueView = [[UIImageView alloc] init];
        //设置需要显示的图片
        _blueView.image= [UIImage imageNamed:@"home_i_show_view_icon"];
    }
    return _blueView;
}

- (void)animationWith:(CGFloat)value index:(NSInteger)index
{
    CALayer *layer = [CALayer layer];
    if (index == 0) {
        layer = self.focusView.layer;
    } else {
        layer = self.zoomView.layer;
    }
    
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

- (void)setupConstraints
{
    __weak JYRulesView *weakSelf = self;
    
    [self.focusView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.mas_equalTo(-(screenH - 30) * 0.5);
        make.leading.equalTo(weakSelf);
        make.trailing.equalTo(weakSelf);
    }];
    
    [self.zoomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.top.bottom.trailing.mas_equalTo(weakSelf.focusView);
    }];
    
    [self.blueView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.centerX.equalTo(weakSelf);
        make.size.mas_equalTo(CGSizeMake(50, 30));
    }];
}

@end

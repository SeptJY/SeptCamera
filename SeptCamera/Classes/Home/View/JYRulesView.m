//
//  JYRulesView.m
//  SeptCamera
//
//  Created by Sept on 16/5/31.
//  Copyright © 2016年 九月. All rights reserved.
//

#import "JYRulesView.h"

@interface JYRulesView ()

@property (strong, nonatomic) CALayer *focusView;

@property (strong, nonatomic) CALayer *zoomView;

@end

@implementation JYRulesView

/** 刻度尺图片View */
- (CALayer *)focusView
{
    if (!_focusView) {
        
        _focusView = [CALayer layer];
        //设置需要显示的图片
        _focusView.contents=(id)[UIImage imageNamed:@"1x_focus"].CGImage;
        
        [self.layer  addSublayer:_focusView];
    }
    return _focusView;
}

- (CALayer *)zoomView
{
    if (!_zoomView) {
        
        _zoomView = [CALayer layer];
        _zoomView.contents=(id)[UIImage imageNamed:@"home_dz_rule_icon"].CGImage;
        _zoomView.hidden = YES;
        
        [self.layer  addSublayer:_zoomView];
    }
    return _zoomView;
}


@end

//
//  JYVideoView.h
//  SeptCamera
//
//  Created by Sept on 16/5/31.
//  Copyright © 2016年 九月. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol JYVideoViewDelegate <NSObject>

@optional
- (void)videoViewBtnOnClick:(UIButton *)btn;

@end

@interface JYVideoView : UIView

@property (weak, nonatomic) id<JYVideoViewDelegate> delegate;

+ (instancetype)videoView;

@end

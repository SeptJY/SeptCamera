//
//  JYLeftTopView.h
//  SeptCamera
//
//  Created by Sept on 16/5/17.
//  Copyright © 2016年 九月. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol JYLeftTopViewDelegate <NSObject>

@optional
- (void)leftTopSettingBtnOnClick;

@end

@interface JYLeftTopViewMasnory : UIView

@property (strong, nonatomic) UILabel *quickLabel;

@property (weak, nonatomic) id<JYLeftTopViewDelegate> delegate;

@end

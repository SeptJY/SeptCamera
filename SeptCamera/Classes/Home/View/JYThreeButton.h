//
//  JYThreeButton.h
//  SeptCamera
//
//  Created by Sept on 16/5/19.
//  Copyright © 2016年 九月. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol JYThreeButtonDelegate <NSObject>

@optional
- (void)threeButtonOnClick:(UIButton *)btn;

@end

@interface JYThreeButton : UIView

@property (weak, nonatomic) id<JYThreeButtonDelegate> delegate;

@end

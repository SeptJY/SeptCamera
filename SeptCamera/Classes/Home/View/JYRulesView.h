//
//  JYRulesView.h
//  SeptCamera
//
//  Created by Sept on 16/5/31.
//  Copyright © 2016年 九月. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JYRulesView : UIView

+ (instancetype)rulesView;

- (void)animationWith:(CGFloat)value index:(NSInteger)index;

@end

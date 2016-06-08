//
//  JYSeletcedView.h
//  SeptCamera
//
//  Created by Sept on 16/6/1.
//  Copyright © 2016年 九月. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JYSeletcedView : UIView

@property (strong, nonatomic) NSArray *dataArray;

+ (instancetype)seletcedViewWithData:(NSArray *)dataArray;

@end

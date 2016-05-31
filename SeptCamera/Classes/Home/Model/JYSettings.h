//
//  JYSettings.h
//  plist的存储和修改
//
//  Created by Sept on 16/5/30.
//  Copyright © 2016年 九月. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JYSettings : NSObject

@property (copy, nonatomic) NSString *title;

@property (copy, nonatomic) NSString *subTitle;

@property (strong, nonatomic) NSArray *content;

@end

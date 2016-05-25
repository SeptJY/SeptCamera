//
//  JYCustomSlider.h
//  SeptCamera
//
//  Created by Sept on 16/5/24.
//  Copyright © 2016年 九月. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JYCustomSlider : UITableViewCell

+ (instancetype)cellWithTableView:(UITableView *)tableView;

@property (copy, nonatomic) NSString *title;

@end

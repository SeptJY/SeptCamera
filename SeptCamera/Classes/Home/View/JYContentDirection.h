//
//  JYContentCell.h
//  SeptCamera
//
//  Created by Sept on 16/5/19.
//  Copyright © 2016年 九月. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JYContentDirection : UITableViewCell

+ (instancetype)cellWithTableView:(UITableView *)tableView;

@property (copy, nonatomic) NSString *bigTitle;
@property (copy, nonatomic) NSString *smallTitle;

@end

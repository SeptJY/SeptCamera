//
//  JYBanlanceBtn.m
//  SeptCamera
//
//  Created by Sept on 16/5/24.
//  Copyright © 2016年 九月. All rights reserved.
//

#import "JYBanlanceBtn.h"

@implementation JYBanlanceBtn

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

+ (instancetype)cellWithTableView:(UITableView *)tableView
{
    static NSString *ID = @"banlanceBtn";
    
    JYBanlanceBtn *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    
    if (cell == nil) {
        cell = [[JYBanlanceBtn alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ID];
    }
    return cell;
}

@end

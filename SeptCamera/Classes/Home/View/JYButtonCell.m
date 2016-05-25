//
//  JYButtonCell.m
//  SeptCamera
//
//  Created by Sept on 16/5/24.
//  Copyright © 2016年 九月. All rights reserved.
//

#import "JYButtonCell.h"

@interface JYButtonCell ()

@property (weak, nonatomic) IBOutlet UIButton *button;

@end

@implementation JYButtonCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (IBAction)buttonOnClick:(UIButton *)sender
{
    
}

+ (instancetype)cellWithTableView:(UITableView *)tableView
{
    static NSString *ID = @"button";
    
    JYButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    
    if (cell == nil) {
        cell = [[JYButtonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ID];
    }
    return cell;
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    
    [self.button setTitle:title forState:UIControlStateNormal];
}

@end

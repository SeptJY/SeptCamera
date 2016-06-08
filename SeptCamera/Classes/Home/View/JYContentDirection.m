//
//  JYContentCell.m
//  SeptCamera
//
//  Created by Sept on 16/5/19.
//  Copyright © 2016年 九月. All rights reserved.
//

#import "JYContentDirection.h"
#import "JYSettings.h"

@interface JYContentDirection ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UILabel *smallLabel;
@end

@implementation JYContentDirection

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

+ (instancetype)cellWithTableView:(UITableView *)tableView
{
    static NSString *ID = @"direction";
    
    JYContentDirection *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    
    if (cell == nil) {
        cell = [[JYContentDirection alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ID];
    }
    return cell;
}

- (void)setBigTitle:(NSString *)bigTitle
{
    _bigTitle = bigTitle;
    
    self.titleLabel.text = bigTitle;
}

- (void)setSmallTitle:(NSString *)smallTitle
{
    _smallTitle = smallTitle;
    
    self.smallLabel.text = smallTitle;
}

- (void)setSetting:(JYSettings *)setting
{
    _setting = setting;
    
    self.titleLabel.text = setting.title;
    self.smallLabel.text = setting.subTitle;
}

@end

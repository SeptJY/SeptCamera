//
//  JYContentSwitch.m
//  SeptCamera
//
//  Created by Sept on 16/5/24.
//  Copyright © 2016年 九月. All rights reserved.
//

#import "JYContentSwitch.h"

@interface JYContentSwitch ()


@property (weak, nonatomic) IBOutlet UILabel *mTitleLabel;
@property (weak, nonatomic) IBOutlet UISwitch *mSwitch;

@end

@implementation JYContentSwitch

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.mSwitch.transform = CGAffineTransformMakeScale(.65, .65);
}

+ (instancetype)cellWithTableView:(UITableView *)tableView
{
    static NSString *ID = @"switch";
    
    JYContentSwitch *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    
    if (cell == nil) {
        cell = [[JYContentSwitch alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ID];
    }
    return cell;
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    
    self.mTitleLabel.text = title;
}

- (IBAction)switchValueChange:(UISwitch *)sender
{
    
}
@end

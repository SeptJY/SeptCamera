//
//  JYCustomSlider.m
//  SeptCamera
//
//  Created by Sept on 16/5/24.
//  Copyright © 2016年 九月. All rights reserved.
//

#import "JYCustomSlider.h"

@interface JYCustomSlider ()

@property (weak, nonatomic) IBOutlet UILabel *mTitleLabel;

@property (weak, nonatomic) IBOutlet UISlider *slider;

@property (weak, nonatomic) IBOutlet UIButton *btn;
@end

@implementation JYCustomSlider

- (void)awakeFromNib {
    [super awakeFromNib];
    
    // Initialization code
    [self.slider setThumbImage:[UIImage imageWithImage:[UIImage imageNamed:@"home_slider_thump_icon"] scaledToWidth:15] forState:UIControlStateNormal];
    
    [self.slider setThumbImage:[UIImage imageWithImage:[UIImage imageNamed:@"home_slider_thump_icon"] scaledToWidth:15] forState:UIControlStateHighlighted];
}

+ (instancetype)cellWithTableView:(UITableView *)tableView
{
    static NSString *ID = @"slider";
    
    JYCustomSlider *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    
    if (cell == nil) {
        cell = [[JYCustomSlider alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ID];
    }
    return cell;
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    
    self.mTitleLabel.text = title;
}

@end

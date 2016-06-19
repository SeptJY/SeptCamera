//
//  JYCollectionCell.m
//  TestCollection
//
//  Created by Sept on 16/6/15.
//  Copyright © 2016年 九月. All rights reserved.
//

#import "JYCollectionCell.h"

@interface JYCollectionCell()

@property (strong, nonatomic) UILabel *textLabel;

@end

@implementation JYCollectionCell

- (instancetype)init {
    if (self = [super init]) {
        [self.contentView addSubview:self.textLabel];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self.contentView addSubview:self.textLabel];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self.contentView addSubview:self.textLabel];
    }
    return self;
}

- (UILabel *)textLabel
{
    if (!_textLabel) {
        
        _textLabel = [[UILabel alloc] init];
        _textLabel.textColor = [UIColor yellowColor];
        _textLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _textLabel;
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    
    self.textLabel.text = title;
}

- (void)layoutSubviews
{
    self.textLabel.frame = self.contentView.bounds;
}

@end

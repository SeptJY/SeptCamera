//
//  JYLeftTopView.m
//  SeptCamera
//
//  Created by Sept on 16/5/17.
//  Copyright © 2016年 九月. All rights reserved.
//

#import "JYLeftTopView.h"
#import "Masonry.h"

@interface JYLeftTopView ()

@property (strong, nonatomic) UIImageView *bgImageView;

@property (strong, nonatomic) UIButton *quickBtn;
@property (strong, nonatomic) UIButton *settingBtn;

@property (strong, nonatomic) UIImageView *batterImgView;

@property (strong, nonatomic) UIView *batterView;

@end

@implementation JYLeftTopView

- (void)awakeFromNib
{
    [self addSubview:self.bgImageView];
    [self addSubview:self.quickBtn];
    [self addSubview:self.settingBtn];
    [self addSubview:self.quickLabel];
    [self addSubview:self.batterImgView];
    [self.batterImgView addSubview:self.batterView];
    
    [self setupConstraints];
}

- (void)settingBtnOnClick
{
    
}

- (UIView *)batterView
{
    if (!_batterView) {
        
        _batterView = [[UIView alloc] init];
        
        _batterView.backgroundColor = [UIColor yellowColor];
    }
    return _batterView;
}

- (UIImageView *)batterImgView
{
    if (!_batterImgView) {
        
        _batterImgView = [[UIImageView alloc] init];
        _batterImgView.image = [UIImage imageNamed:@"batter"];
    }
    return _batterImgView;
}

- (UILabel *)quickLabel
{
    if (!_quickLabel) {
        
        _quickLabel = [[UILabel alloc] init];
        
        _quickBtn.backgroundColor = [UIColor clearColor];
    }
    return _quickLabel;
}

- (UIButton *)quickBtn
{
    if (!_quickBtn) {
        
        _quickBtn = [[UIButton alloc] init];
        
        [_quickBtn setImage:[UIImage imageNamed:@"dub_arrow_down"] forState:UIControlStateNormal];
        [_quickBtn setImage:[UIImage imageNamed:@"dub_arrow_up"] forState:UIControlStateSelected];
    }
    return _quickBtn;
}

- (UIButton *)settingBtn
{
    if (!_settingBtn) {
        
        _settingBtn = [[UIButton alloc] init];
        
        [_settingBtn setImage:[UIImage imageNamed:@"logo_setup_off"] forState:UIControlStateNormal];
        [_settingBtn setImage:[UIImage imageNamed:@"logo_setup_on"] forState:UIControlStateSelected];
        
        [self.settingBtn addTarget:self action:@selector(settingBtnOnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _settingBtn;
}

- (UIImageView *)bgImageView
{
    if (!_bgImageView) {
        
        _bgImageView = [[UIImageView alloc] init];
        _bgImageView.image = [UIImage imageNamed:@"left_bg_icon"];
    }
    return _bgImageView;
}

- (void)setupConstraints
{
    __weak JYLeftTopView *weakSelf = self;
    [self.bgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        // bgImageView顶部距离self = 10
        make.top.equalTo(weakSelf).offset(10);
        make.left.equalTo(weakSelf).offset(10);
        make.bottom.equalTo(weakSelf).offset(-10);
    }];

    [self.settingBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(weakSelf.bgImageView);
        make.top.equalTo(weakSelf);
        make.bottom.equalTo(weakSelf);
        // settingBtn和quickBtn的宽度相等
        make.width.mas_equalTo(weakSelf.quickBtn);
    }];
    
    [self.quickBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(weakSelf.bgImageView);
        // quickBtn的顶部和底部和settingBtn同一致
        make.bottom.top.mas_equalTo(weakSelf.settingBtn);
        make.right.mas_equalTo(weakSelf.settingBtn.mas_left);
    }];
    
    [self.quickLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(weakSelf.bgImageView);
        make.top.equalTo(weakSelf.settingBtn);
        make.bottom.equalTo(weakSelf.settingBtn);
        make.width.mas_equalTo(self.quickBtn);
    }];
    
    [self.batterImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(25, 12));
        make.right.equalTo(weakSelf).offset(-10);
        // batterImgView的左边和bgImageView的右边相差8个像素
        make.left.mas_equalTo(weakSelf.bgImageView.mas_right).offset(8);
        make.centerY.equalTo(weakSelf);
    }];
    
    [self.batterView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.batterImgView).offset(2);
        make.left.equalTo(weakSelf.batterImgView).offset(2);
        make.bottom.equalTo(weakSelf.batterImgView).offset(-2);
        make.right.equalTo(weakSelf.batterImgView).offset(-4);
    }];
}

@end

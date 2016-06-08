//
//  JYVideoView.m
//  SeptCamera
//
//  Created by Sept on 16/5/31.
//  Copyright © 2016年 九月. All rights reserved.
//

#import "JYVideoView.h"

@interface JYVideoView ()

@property (strong, nonatomic) UIButton *videoBtn;

@property (strong, nonatomic) UIButton *photoBtn;

@property (strong, nonatomic) UIButton *iconsBtn;

@end

@implementation JYVideoView

+ (instancetype)videoView
{
    return [[self alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self addSubview:self.videoBtn];
        [self addSubview:self.photoBtn];
        [self addSubview:self.iconsBtn];
        [self setupConstraints];
    }
    return self;
}

- (UIButton *)videoBtn
{
    if (!_videoBtn) {
        
        _videoBtn = [[UIButton alloc] init];
        
        [_videoBtn setImage:[UIImage imageNamed:@"record_start"] forState:UIControlStateNormal];
        [_videoBtn setImage:[UIImage imageNamed:@"record_stop"] forState:UIControlStateSelected];
        _videoBtn.tag = 20;
        
        [_videoBtn addTarget:self action:@selector(videoViewBtnOnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _videoBtn;
}

- (UIButton *)photoBtn
{
    if (!_photoBtn) {
        
        _photoBtn = [[UIButton alloc] init];
        
        [_photoBtn setImage:[UIImage imageNamed:@"camara"] forState:UIControlStateNormal];
        _photoBtn.tag = 21;
        _photoBtn.hidden = YES;
        
        [_photoBtn addTarget:self action:@selector(videoViewBtnOnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _photoBtn;
}

- (UIButton *)iconsBtn
{
    if (!_iconsBtn) {
        
        _iconsBtn = [[UIButton alloc] init];
        
        _iconsBtn.tag = 22;
        _iconsBtn.backgroundColor = [UIColor yellowColor];
        
        [_iconsBtn addTarget:self action:@selector(videoViewBtnOnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _iconsBtn;
}

- (void)videoViewBtnOnClick:(UIButton *)btn
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoViewBtnOnClick:)]) {
        [self.delegate videoViewBtnOnClick:btn];
    }
}

- (void)setupConstraints
{
    __weak JYVideoView *weakSelf = self;
    
    [self.videoBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.centerY.equalTo(weakSelf);
        make.size.mas_equalTo(CGSizeMake(60, 60));
    }];
    
    [self.photoBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.centerY.equalTo(weakSelf);
        make.size.mas_equalTo(CGSizeMake(60, 60));
    }];
    
    [self.iconsBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(weakSelf);
        make.size.mas_equalTo(CGSizeMake(50, 30));
        make.bottom.equalTo(weakSelf).offset(-10);
    }];
}

@end

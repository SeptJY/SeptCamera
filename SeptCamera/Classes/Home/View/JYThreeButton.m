//
//  JYThreeButton.m
//  SeptCamera
//
//  Created by Sept on 16/5/19.
//  Copyright © 2016年 九月. All rights reserved.
//

#import "JYThreeButton.h"

@interface JYThreeButton ()

@property (strong, nonatomic) UIView *vertical1;

@property (strong, nonatomic) UIView *vertical2;

@property (strong, nonatomic) UIView *vertical3;

@property (strong, nonatomic) UIView *vertical4;

@property (strong, nonatomic) UIView *hengLine1;

@property (strong, nonatomic) UIView *hengLine2;

@property (strong, nonatomic) UIButton *setBtn;
@property (strong, nonatomic) UIButton *wbBtn;
@property (strong, nonatomic) UIButton *evBtn;

@end

@implementation JYThreeButton

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        [self addSubview:self.vertical1];
        [self addSubview:self.vertical4];
        [self addSubview:self.vertical2];
        [self addSubview:self.vertical3];
        [self addSubview:self.hengLine1];
        [self addSubview:self.hengLine2];
        
        [self addSubview:self.setBtn];
        [self addSubview:self.wbBtn];
        [self addSubview:self.evBtn];
        
        [self setupConstraints];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeLanguage) name:@"changeLanguage" object:nil];
    }
    return self;
}

- (void)changeLanguage
{
    [self.setBtn setTitle:[[JYLanguageTool bundle] localizedStringForKey:@"设置" value:nil table:@"Localizable"] forState:UIControlStateNormal];
    [self.wbBtn setTitle:[[JYLanguageTool bundle] localizedStringForKey:@"白平衡" value:nil table:@"Localizable"] forState:UIControlStateNormal];
    [self.evBtn setTitle:[[JYLanguageTool bundle] localizedStringForKey:@"曝光" value:nil table:@"Localizable"] forState:UIControlStateNormal];
}

- (UIButton *)setBtn
{
    if (!_setBtn) {
        
        _setBtn = [JYThreeButton createBtnWithTitle:@"设置" tag:10];
        _setBtn.selected = YES;
        [_setBtn addTarget:self action:@selector(threeButtonOnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _setBtn;
}

- (UIButton *)wbBtn
{
    if (!_wbBtn) {
        
        _wbBtn = [JYThreeButton createBtnWithTitle:@"白平衡" tag:11];
        [_wbBtn addTarget:self action:@selector(threeButtonOnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _wbBtn;
}

- (UIButton *)evBtn
{
    if (!_evBtn) {
        
        _evBtn = [JYThreeButton createBtnWithTitle:@"曝光" tag:12];
        [_evBtn addTarget:self action:@selector(threeButtonOnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _evBtn;
}

+ (UIButton *)createBtnWithTitle:(NSString *)title tag:(NSInteger)tag
{
    UIButton *button = [[UIButton alloc] init];
    
    [button setTitle:NSLocalizedString(title, nil) forState:UIControlStateNormal];
    [button setTitleColor:[UIColor yellowColor] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor grayColor] forState:UIControlStateSelected];
    [button setBackgroundImage:[UIImage imageWithColor:[UIColor clearColor]] forState:UIControlStateNormal];
    [button setBackgroundImage:[UIImage imageWithColor:[UIColor yellowColor]] forState:UIControlStateSelected];
    button.tag = tag;
    
    return button;
}

- (void)threeButtonOnClick:(UIButton *)btn
{
    // 遍历所有按钮，设置不可以选中
    for (int i = 10; i < 13; i ++) {
        UIButton *button = [self viewWithTag:i];
        button.selected = NO;
    }
    // 当前选中的按钮设置成选中
    btn.selected = YES;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(threeButtonOnClick:)]) {
        [self.delegate threeButtonOnClick:btn];
    }
}

- (UIView *)vertical1
{
    if (!_vertical1) {
        
        _vertical1 = [[UIView alloc] init];
        
        _vertical1.backgroundColor = [UIColor yellowColor];
    }
    return _vertical1;
}

- (UIView *)vertical4
{
    if (!_vertical4) {
        
        _vertical4 = [[UIView alloc] init];
        
        _vertical4.backgroundColor = [UIColor yellowColor];
    }
    return _vertical4;
}

- (UIView *)vertical2
{
    if (!_vertical2) {
        
        _vertical2 = [[UIView alloc] init];
        
        _vertical2.backgroundColor = [UIColor yellowColor];
    }
    return _vertical2;
}

- (UIView *)vertical3
{
    if (!_vertical3) {
        
        _vertical3 = [[UIView alloc] init];
        
        _vertical3.backgroundColor = [UIColor yellowColor];
    }
    return _vertical3;
}

- (UIView *)hengLine1
{
    if (!_hengLine1) {
        
        _hengLine1 = [[UIView alloc] init];
        
        _hengLine1.backgroundColor = [UIColor yellowColor];
    }
    return _hengLine1;
}

- (UIView *)hengLine2
{
    if (!_hengLine2) {
        
        _hengLine2 = [[UIView alloc] init];
        
        _hengLine2.backgroundColor = [UIColor yellowColor];
    }
    return _hengLine2;
}


- (void)setupConstraints
{
    __weak JYThreeButton *weakSelf = self;
    
    // 最左边的竖线
    [self.vertical1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(weakSelf).offset(10);
        make.top.equalTo(weakSelf).offset(10);
        make.bottom.equalTo(weakSelf);
        make.width.mas_equalTo(2);
    }];
    
    // 最右边的竖线
    [self.vertical4 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(weakSelf).offset(-10);
        make.width.bottom.top.mas_equalTo(weakSelf.vertical1);
    }];
    
    // 最上面的线
    [self.hengLine1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(weakSelf.vertical1);
        make.trailing.mas_equalTo(weakSelf.vertical4);
        make.bottom.equalTo(weakSelf.vertical1.mas_top);
        make.height.mas_equalTo(2);
    }];
    
    // 最下面的线
    [self.hengLine2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.leading.trailing.mas_equalTo(weakSelf.hengLine1);
        make.top.equalTo(weakSelf.vertical1.mas_bottom);
    }];
    
    [self.setBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(weakSelf.hengLine1.mas_bottom);
        make.left.mas_equalTo(weakSelf.vertical1.mas_right);
        make.bottom.mas_equalTo(weakSelf.hengLine2.mas_top);
    }];
    
    [self.wbBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.mas_equalTo(weakSelf.setBtn);
        make.right.mas_equalTo(weakSelf.evBtn.mas_left).offset(2);
        make.left.mas_equalTo(weakSelf.setBtn.mas_right).offset(2);
    }];
    
    [self.evBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.mas_equalTo(weakSelf.setBtn);
        make.right.mas_equalTo(weakSelf.vertical4.mas_left);
        make.width.mas_equalTo(@[weakSelf.setBtn, weakSelf.wbBtn]);
    }];
    
    // 设置和白平衡之间的竖线
    [self.vertical2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.mas_equalTo(weakSelf.setBtn);
        make.left.mas_equalTo(weakSelf.setBtn.mas_right);
//        make.right.mas_equalTo(weakSelf.wbBtn.mas_left);
        make.width.mas_equalTo(weakSelf.vertical1);
    }];
    
    // 曝光和白平衡之间的竖线
    [self.vertical3 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.mas_equalTo(weakSelf.setBtn);
        make.left.mas_equalTo(weakSelf.wbBtn.mas_right);
//        make.right.mas_equalTo(weakSelf.evBtn.mas_left);
        make.width.mas_equalTo(weakSelf.vertical1);
    }];
}

@end

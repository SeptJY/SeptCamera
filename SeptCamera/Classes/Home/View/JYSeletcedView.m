//
//  JYSeletcedView.m
//  SeptCamera
//
//  Created by Sept on 16/6/1.
//  Copyright © 2016年 九月. All rights reserved.
//

#import "JYSeletcedView.h"

static NSString *ID = @"Seletced";
@interface JYSeletcedView () <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) UITableView *tableView;

@end

@implementation JYSeletcedView

+ (instancetype)seletcedViewWithData:(NSArray *)dataArray
{
    return [[self alloc] initWithContents:dataArray];
}

- (instancetype)initWithContents:(NSArray *)dataArray
{
    self = [super init];
    if (self) {
        
        self.dataArray = dataArray;
        [self setupConstraints];
    }
    return self;
}

- (UITableView *)tableView
{
    if (!_tableView) {
        
        _tableView = [[UITableView alloc] init];
        
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.separatorColor = [UIColor yellowColor];
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.rowHeight = 50;
        
        [self addSubview:_tableView];
    }
    return _tableView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ID];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.tintColor = [UIColor yellowColor];
        cell.textLabel.text = @"SB";
    }
    return cell;
}


- (void)setupConstraints
{
    __weak JYSeletcedView *weakSelf = self;
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.leading.trailing.equalTo(weakSelf);
    }];
}

@end

//
//  JYExposureView.m
//  SeptCamera
//
//  Created by Sept on 16/5/24.
//  Copyright © 2016年 九月. All rights reserved.
//

#import "JYExposureView.h"

#import "JYCustomSlider.h"

@interface JYExposureView () <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) UITableView *tableView;

@property (strong, nonatomic) NSArray *languages;
@property (strong, nonatomic) NSMutableArray *titleArray;

@end

@implementation JYExposureView

+ (instancetype)exposureView
{
    return [[self alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        //        [self addSubview:self.tableView];
        [self setupConstraints];
        
        [self.tableView registerNib:[UINib nibWithNibName:@"JYCustomSlider" bundle:nil] forCellReuseIdentifier:@"slider"];
        
        self.languages = @[@"曝光补偿", @"感  光  度", @"曝光时间", @"曝光偏移"];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeLanguage) name:@"changeLanguage" object:nil];
    }
    return self;
}

- (void)changeLanguage
{
    NSMutableArray *changArray = [NSMutableArray array];
    
    // 2.遍历数组，转换成所需要的语言
    for (NSString *str in self.languages) {
        NSString *mStr = [[JYLanguageTool bundle] localizedStringForKey:str value:nil table:@"Localizable"];
        [changArray addObject:mStr];
    }
    // 3.赋值原来的数组
    self.titleArray = changArray;
    
    [self.tableView reloadData];
}

- (NSMutableArray *)titleArray
{
    if (!_titleArray) {
        
        _titleArray = [NSMutableArray array];
        
        for (NSString *str in self.languages) {
            [_titleArray addObject:NSLocalizedString(str, nil)];
        }
    }
    return _titleArray;
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
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.rowHeight = 50;
        
        [self addSubview:self.tableView];
    }
    return _tableView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.languages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYCustomSlider *cell = [JYCustomSlider cellWithTableView:tableView];
    cell.backgroundColor = [UIColor clearColor];
    cell.title = self.titleArray[indexPath.row];
    
    return cell;
}

- (void)setupConstraints
{
    __weak JYExposureView *weakSelf = self;
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(weakSelf).offset(10);
        make.leading.equalTo(weakSelf).offset(10);
        make.bottom.equalTo(weakSelf).offset(-10);
        make.trailing.equalTo(weakSelf).offset(-10);
    }];
}

@end

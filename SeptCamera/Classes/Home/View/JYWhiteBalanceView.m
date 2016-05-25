//
//  JYWhiteBalanceView.m
//  SeptCamera
//
//  Created by Sept on 16/5/24.
//  Copyright © 2016年 九月. All rights reserved.
//

#import "JYWhiteBalanceView.h"
#import "JYBanlanceBtn.h"
#import "JYCustomSlider.h"

@interface JYWhiteBalanceView () <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) UITableView *tableView;

@property (strong, nonatomic) NSMutableArray *titleArray;
@property (strong, nonatomic) NSArray *languages;

@end

@implementation JYWhiteBalanceView

+ (instancetype)whiteBalance
{
    return [[self alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
//        [self addSubview:self.tableView];
        [self setupConstraints];
        
        [self.tableView registerNib:[UINib nibWithNibName:@"JYBanlanceBtn" bundle:nil] forCellReuseIdentifier:@"banlanceBtn"];
        [self.tableView registerNib:[UINib nibWithNibName:@"JYCustomSlider" bundle:nil] forCellReuseIdentifier:@"slider"];
        
        self.languages = @[@"色温", @"色彩", @"饱和度"];
        
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 1:
            return 3;
            
        default:
            return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
        {
            JYBanlanceBtn *cell = [JYBanlanceBtn cellWithTableView:tableView];
            cell.backgroundColor = [UIColor clearColor];
            
            return cell;
        }
        case 1:
        {
            JYCustomSlider *cell = [JYCustomSlider cellWithTableView:tableView];
            cell.backgroundColor = [UIColor clearColor];
            cell.title = self.titleArray[indexPath.row];
            
            return cell;
        }
            
        default:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
            return cell;
        }
    }
}

- (void)setupConstraints
{
    __weak JYWhiteBalanceView *weakSelf = self;
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(weakSelf).offset(10);
        make.leading.equalTo(weakSelf).offset(10);
        make.bottom.equalTo(weakSelf).offset(-10);
        make.trailing.equalTo(weakSelf).offset(-10);
    }];
}

@end

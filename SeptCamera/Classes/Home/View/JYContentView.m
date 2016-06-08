//
//  JYContentView.m
//  SeptCamera
//
//  Created by Sept on 16/5/19.
//  Copyright © 2016年 九月. All rights reserved.
//

#import "JYContentView.h"
#import "JYThreeButton.h"
#import "JYContentDirection.h"
#import "JYContentSwitch.h"
#import "JYCustomSlider.h"
#import "JYButtonCell.h"
#import "JYWhiteBalanceView.h"
#import "JYExposureView.h"
#import "MJExtension.h"
#import "JYSettings.h"
#import "JYSeletcedView.h"

@interface JYContentView () <UITableViewDelegate, UITableViewDataSource, JYThreeButtonDelegate>

@property (strong, nonatomic) JYThreeButton *threeBtn;

@property (strong, nonatomic) UITableView *tableView;

@property (strong, nonatomic) NSMutableArray *settingsArray;
@property (strong, nonatomic) NSMutableArray *changeArray;

@property (strong, nonatomic) JYWhiteBalanceView *whiteView;
@property (strong, nonatomic) JYExposureView *exposureView;

@property (strong, nonatomic) JYSeletcedView *selView;

@end

@implementation JYContentView

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        [self addSubview:self.threeBtn];
        [self addSubview:self.whiteView];
        [self addSubview:self.exposureView];
        
        [self setupConstraints];
        
        [self.tableView registerNib:[UINib nibWithNibName:@"JYContentDirection" bundle:nil] forCellReuseIdentifier:@"direction"];
        [self.tableView registerNib:[UINib nibWithNibName:@"JYContentSwitch" bundle:nil] forCellReuseIdentifier:@"switch"];
        [self.tableView registerNib:[UINib nibWithNibName:@"JYCustomSlider" bundle:nil] forCellReuseIdentifier:@"slider"];
        [self.tableView registerNib:[UINib nibWithNibName:@"JYButtonCell" bundle:nil] forCellReuseIdentifier:@"button"];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeLanguage) name:@"changeLanguage" object:nil];
    }
    return self;
}

- (void)changeLanguage
{
    NSMutableArray *changArray = [NSMutableArray array];
    for (JYSettings *setting in self.settingsArray) {
        JYSettings *mSet = [[JYSettings alloc] init];
        
        mSet.title = [[JYLanguageTool bundle] localizedStringForKey:setting.title value:nil table:@"Localizable"];
        mSet.subTitle = [[JYLanguageTool bundle] localizedStringForKey:setting.subTitle value:nil table:@"Localizable"];
        
        [changArray addObject:mSet];
    }
    self.changeArray = changArray;
    
    [self.tableView reloadData];
}

- (NSMutableArray *)settingsArray
{
    if (!_settingsArray) {
        _settingsArray = [NSMutableArray array];
        
        // 获取工程中创建的plist数据
        NSString *path = [[NSBundle mainBundle] pathForResource:@"SettingData.plist" ofType:nil];
        NSMutableArray *mArr = [NSMutableArray arrayWithContentsOfFile:path];
        
        // 获取手动创建的data数据
        NSArray *sandboxpath= NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        //获取完整路径
        NSString *documentsDirectory = [sandboxpath objectAtIndex:0];
        NSString *plistPath = [documentsDirectory stringByAppendingPathComponent:@"data.plist"];
        
        // 判断data.plist文件是否存在
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
        if (dict == nil) {
            // 创建data.plist
            NSFileManager* fm = [NSFileManager defaultManager];
            [fm createFileAtPath:plistPath contents:nil attributes:nil];
            
            // 把工程中创建的plist数据写入到手动创建的data.plist文件中
            [mArr writeToFile:plistPath atomically:YES];
        }
        
        NSMutableArray *arr = [NSMutableArray arrayWithContentsOfFile:plistPath];
        
        NSMutableArray *mSettings = [NSMutableArray array];
        for (NSMutableDictionary *dict in arr) {
            JYSettings *mSet = [JYSettings mj_objectWithKeyValues:dict];
            
            [mSettings addObject:mSet];
        }
        _settingsArray = mSettings;
    }
    return _settingsArray;
}

- (NSMutableArray *)changeArray
{
    if (!_changeArray) {
        _changeArray = [NSMutableArray array];
        
        _changeArray = self.settingsArray;
    }
    return _changeArray;
}

- (JYSeletcedView *)selView
{
    if (!_selView) {
        
        _selView = [[JYSeletcedView alloc] init];
        _selView.backgroundColor = [UIColor clearColor];
        _selView.hidden = YES;
        
        [self addSubview:_selView];
    }
    return _selView;
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
        
        [self addSubview:self.tableView];
    }
    return _tableView;
}

- (JYWhiteBalanceView *)whiteView
{
    if (!_whiteView) {
        
        _whiteView = [JYWhiteBalanceView whiteBalance];
        _whiteView.hidden = YES;
    }
    return _whiteView;
}

- (JYExposureView *)exposureView
{
    if (!_exposureView) {
        
        _exposureView = [JYExposureView exposureView];
        _exposureView.hidden = YES;
    }
    return _exposureView;
}

- (JYThreeButton *)threeBtn
{
    if (!_threeBtn) {
        
        _threeBtn = [[JYThreeButton alloc] init];
        _threeBtn.delegate = self;
    }
    return _threeBtn;
}

#pragma mark -------------------------> JYThreeButtonDelegate
- (void)threeButtonOnClick:(UIButton *)btn
{
    switch (btn.tag) {
        case 10:
        {
            self.tableView.hidden = NO;
            self.exposureView.hidden = !self.tableView.hidden;
            self.whiteView.hidden = !self.tableView.hidden;
        }
            break;
        case 11:
        {
            self.whiteView.hidden = NO;
            self.exposureView.hidden = !self.whiteView.hidden;
            self.tableView.hidden = !self.whiteView.hidden;
        }
            break;
        case 12:
        {
            self.exposureView.hidden = NO;
            self.whiteView.hidden = !self.exposureView.hidden;
            self.tableView.hidden = !self.exposureView.hidden;
        }
            break;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 9;
        case 1:
            return 2;
            
        default:
            return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
        {
            JYSettings *setting = self.changeArray[indexPath.row];
            
            JYContentDirection *cell = [JYContentDirection cellWithTableView:tableView];
            cell.backgroundColor = [UIColor clearColor];
//            cell.bigTitle = self.titleArray[indexPath.row];
//            cell.smallTitle = self.titleSmallArray[indexPath.row];
            cell.setting = setting;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            return cell;
        }
        case 1:
        {
            JYSettings *setting = self.changeArray[indexPath.row + 9];
            JYContentSwitch *cell = [JYContentSwitch cellWithTableView:tableView];
            cell.backgroundColor = [UIColor clearColor];
            cell.title = setting.title;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            return cell;
        }
        case 2:
        {
            JYSettings *setting = self.changeArray[indexPath.row + 9 + 2];
            JYCustomSlider *cell = [JYCustomSlider cellWithTableView:tableView];
            cell.backgroundColor = [UIColor clearColor];
            cell.title = setting.title;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            return cell;
        }
        case 3:
        {
            JYSettings *setting = [self.changeArray lastObject];
            JYButtonCell *cell = [JYButtonCell cellWithTableView:tableView];
            cell.backgroundColor = [UIColor clearColor];
            cell.title = setting.title;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            return cell;
        }
        default:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
            return cell;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"%ld", (long)indexPath.row);
}

- (void)setupConstraints
{
    __weak JYContentView *weakSelf = self;
    
    [self.threeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(weakSelf);
        make.height.mas_equalTo(42);
    }];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(weakSelf.threeBtn.mas_bottom).offset(10);
        make.leading.equalTo(weakSelf);
        make.bottom.equalTo(weakSelf).offset(-10);
        make.trailing.equalTo(weakSelf).offset(-10);
    }];
    
    [self.whiteView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(weakSelf.threeBtn.mas_bottom).offset(15);
        make.leading.equalTo(weakSelf);
        make.bottom.equalTo(weakSelf).offset(-15);
        make.trailing.equalTo(weakSelf).offset(-10);
    }];
    
    [self.exposureView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.bottom.trailing.mas_equalTo(weakSelf.whiteView);
    }];
    
    [self.selView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.bottom.trailing.mas_equalTo(weakSelf.whiteView);
    }];
}

@end

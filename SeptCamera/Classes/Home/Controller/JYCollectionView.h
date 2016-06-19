//
//  JYCollectionView.h
//  TestCollection
//
//  Created by Sept on 16/6/15.
//  Copyright © 2016年 九月. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol JYCollectionViewDelegate <NSObject>

@optional
- (void)collectionViewDidSelectIndex:(NSInteger)index;

@end

@interface JYCollectionView : UIView

@property (weak, nonatomic) id<JYCollectionViewDelegate> delegate;

+ (instancetype)collectionViewWithSize:(CGSize)size;

@end

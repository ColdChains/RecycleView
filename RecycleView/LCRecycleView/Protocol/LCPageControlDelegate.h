//
//  LCPageControlDelegate.h
//  LC
//
//  Created by lax on 2022/4/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LCPageControlDelegate <NSObject>

@optional

// 设置总页数
- (void)pageControlSetNumberOfPages:(NSInteger)numberOfPages;

// 设置当前页数
- (void)pageControlSetCurrentPage:(NSInteger)currentPage;

// 点击指示器
- (void)pageControlDidSelect:(UIView<LCPageControlDelegate> *)pageControl atPage:(NSInteger)currentPage;

@end

NS_ASSUME_NONNULL_END

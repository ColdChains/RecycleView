//
//  LCPageControl.h
//  RecycleView
//
//  Created by lax on 2022/4/7.
//

#import <UIKit/UIKit.h>
#import "LCPageControlDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface LCPageControl : UIPageControl <LCPageControlDelegate>

// 代理
@property (nonatomic, weak) id <LCPageControlDelegate> delegate;

@end

NS_ASSUME_NONNULL_END

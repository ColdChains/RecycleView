//
//  ViewController.h
//  RecycleViewDemo
//
//  Created by lax on 2022/7/18.
//

#import "ViewController.h"
#import <Masonry/Masonry.h>
#import <RecycleView/RecycleView.h>

@interface ViewController () <LCRecycleViewDelegate, LCRecycleViewDataSource>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 卡片效果
    LCRecycleView *recycleView = [[LCRecycleView alloc] init];
    recycleView.delegate = self;
    recycleView.dataSource = self;
    recycleView.edgeInsets = UIEdgeInsetsMake(0, 18, 0, 18);
    recycleView.minSpacing = 12;
    recycleView.canLoop = NO;
    recycleView.tag = 100;
    
    [self.view addSubview:recycleView];
    [recycleView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(0);
        make.top.mas_equalTo(88);
        make.height.mas_equalTo(100);
    }];
    
    // 轮播图效果
    LCRecycleView *bannerView = [[LCRecycleView alloc] init];
    bannerView.delegate = self;
    bannerView.dataSource = self;
    bannerView.edgeInsets = UIEdgeInsetsMake(0, 18, 0, 18);
    bannerView.minSpacing = 12;
    bannerView.canLoop = YES;
    
    LCPageControl *control = [[LCPageControl alloc] init];
    control.backgroundColor = [UIColor lightGrayColor];
    control.pageIndicatorTintColor = [UIColor redColor];
    control.currentPageIndicatorTintColor = [UIColor whiteColor];
    control.delegate = bannerView;
    bannerView.pageControl = control;
    
    [self.view addSubview:bannerView];
    [bannerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(0);
        make.top.mas_equalTo(recycleView.mas_bottom).offset(44);
        make.height.mas_equalTo(333);
    }];
}

// 返回数量
- (NSInteger)numberOfItemsInRecycleView:(LCRecycleView *)recycleView {
    return recycleView.tag == 100 ? 10 : 3;
}

// 返回大小
- (CGSize)sizeForItemInRecycleView:(LCRecycleView *)recycleView {
    return recycleView.tag == 100 ? CGSizeMake(100, 100) : CGSizeMake(UIScreen.mainScreen.bounds.size.width - 18 * 2, 333);
}

// 返回样式
- (UIView *)recycleView:(LCRecycleView *)recycleView cellForItemAtIndex:(NSInteger)index {
    UIImageView *cell = (UIImageView *)[recycleView dequeueReusableCell];
    if (!cell) {
        cell = [[UIImageView alloc] init];
    }
    cell.backgroundColor = @[[UIColor greenColor], [UIColor orangeColor], [UIColor redColor]][index % 3];
    return cell;
}

// 点击
- (void)recycleView:(LCRecycleView *)recycleView didSelectItemAtIndex:(NSInteger)index {
    NSLog(@"%ld", index);
}

@end

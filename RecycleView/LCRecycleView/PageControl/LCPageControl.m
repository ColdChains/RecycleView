//
//  LCPageControl.m
//  RecycleView
//
//  Created by lax on 2022/4/7.
//

#import "LCPageControl.h"

@implementation LCPageControl

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self addTarget:self action:@selector(pageValueChagned) forControlEvents:UIControlEventValueChanged];
    }
    return self;
}

- (void)pageValueChagned {
    if ([self.delegate respondsToSelector:@selector(pageControlDidSelect:atPage:)]) {
        [self.delegate pageControlDidSelect:self atPage:self.currentPage];
    }
}

- (void)pageControlSetNumberOfPages:(NSInteger)numberOfPages {
    self.numberOfPages = numberOfPages;
}

- (void)pageControlSetCurrentPage:(NSInteger)currentPage {
    self.currentPage = currentPage;
}

- (void)pageControlDidSelect:(UIView<LCPageControlDelegate> *)pageControl atPage:(NSInteger)currentPage {
    self.currentPage = currentPage;
}

@end

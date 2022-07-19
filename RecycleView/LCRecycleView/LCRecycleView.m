//
//  RecycleView.m
//  RecycleView
//
//  Created by lax on 2022/1/26.
//

#import "LCRecycleView.h"
#import "LCRecycleScrollView.h"
#import <Masonry/Masonry.h>

@interface LCRecycleView () <UIGestureRecognizerDelegate>

// 滚动视图
@property (nonatomic, strong) LCRecycleScrollView *scrollView;

// 总页数
@property (nonatomic) NSInteger numberOfItems;

// 需要显示的总页数
@property (nonatomic) NSInteger showNumberOfItems;

// 当前页数
@property (nonatomic) NSInteger currentIndex;

// 一页的大小
@property (nonatomic) CGSize itemSize;

// 定时器
@property (nonatomic, weak) NSTimer *timer;

// 实际设置的Cell间距(受minScale影响)
@property (nonatomic) CGFloat factSpacing;

// 可见Cell的范围
@property (nonatomic) NSRange visibleRange;

// Cell数组
@property (nonatomic, strong) NSMutableArray *cells;

// 可复用Cell数组
@property (nonatomic, strong) NSMutableArray *reusableCells;

@end

@implementation LCRecycleView

// MARK: - Getter Settter

- (LCRecycleScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[LCRecycleScrollView alloc] init];
        _scrollView.delegate = self;
        _scrollView.scrollsToTop = NO;
        _scrollView.clipsToBounds = NO;
        _scrollView.pagingEnabled = YES;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
    }
    return _scrollView;
}

- (NSMutableArray *)cells {
    if (!_cells) {
        _cells = [NSMutableArray array];
    }
    return _cells;
}

- (NSMutableArray *)reusableCells {
    if (!_reusableCells) {
        _reusableCells = [NSMutableArray array];
    }
    return _reusableCells;
}

- (void)setNumberOfItems:(NSInteger)numberOfItems {
    _numberOfItems = numberOfItems;
    if ([self.pageControl respondsToSelector:@selector(pageControlSetNumberOfPages:)]) {
        [self.pageControl pageControlSetNumberOfPages:self.numberOfItems];
    }
}

- (void)setCurrentIndex:(NSInteger)currentIndex {
    _currentIndex = currentIndex;
    if (!self.canLoop && currentIndex == self.numberOfItems - 1 && (NSInteger)self.frame.size.width % (NSInteger)(self.itemSize.width + self.minSpacing) > self.itemSize.width / 2) {
        _scrollView.pagingEnabled = NO;
    } else {
        _scrollView.pagingEnabled = YES;
    }
    if ([self.pageControl respondsToSelector:@selector(pageControlSetCurrentPage:)]) {
        [self.pageControl pageControlSetCurrentPage:currentIndex];
    }
}

- (void)setPageControl:(UIView<LCPageControlDelegate> *)pageControl {
    _pageControl = pageControl;
    [self addSubview:pageControl];
    [self layoutPageControl];
    if ([pageControl respondsToSelector:@selector(pageControlSetCurrentPage:)]) {
        [pageControl pageControlSetCurrentPage:self.currentIndex];
    }
}

- (void)setPageControlEdgeInsets:(UIEdgeInsets)pageControlEdgeInsets {
    _pageControlEdgeInsets = pageControlEdgeInsets;
    [self layoutPageControl];
}

- (void)layoutPageControl {
    if (!self.pageControl.superview) { return; }
    switch (self.orientation) {
        case LCRecycleViewOrientationHorizontal:
        {
            [self.pageControl mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.mas_equalTo(self.pageControlEdgeInsets.left);
                make.right.mas_equalTo(-self.pageControlEdgeInsets.right);
                make.bottom.mas_equalTo(-self.pageControlEdgeInsets.bottom);
            }];
            break;
        }
        case LCRecycleViewOrientationVertical:
        {
            [self.pageControl mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.mas_equalTo(self.pageControlEdgeInsets.left);
                make.top.mas_equalTo(self.pageControlEdgeInsets.right);
                make.bottom.mas_equalTo(-self.pageControlEdgeInsets.bottom);
            }];
            break;
        }
    }
}

// MARK: - 系统方法

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self initView];
    }
    return self;
}

- (void)initView {
    self.clipsToBounds = YES;
    
    self.orientation = LCRecycleViewOrientationHorizontal;
    self.alignment = LCRecycleViewAlignmentLeft;
    
    self.canLoop = NO;
    self.autoScroll = NO;
    self.autoScrollTimeInterval = 5.0;
    
    self.scrollNumber = 1;
    self.factSpacing = 0;
    self.minAlpha = 1;
    self.minScale = 1;
        
    [self addSubview:self.scrollView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self reloadData];
}

// 解决当父View释放时，当前视图因为被Timer强引用而不能释放的问题
- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (!newSuperview) {
        [self stopTimer];
    }
}

// 解决当timer释放后 回调scrollViewDidScroll时访问野指针导致崩溃
- (void)dealloc {
    self.scrollView.delegate = nil;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    UIView *view = [touches anyObject].view;
    do {
        if ([self.cells containsObject:view]) {
            NSInteger index = [self.cells indexOfObject:view];
            if (self.delegate && [self.delegate respondsToSelector:@selector(recycleView:didSelectItemAtIndex:)]) {
                [self.delegate recycleView:self didSelectItemAtIndex:index % self.numberOfItems];
            }
        }
        view = view.superview;
    } while (view.superview);
}

// MARK: - Cell复用

// 添加复用Cell
- (void)addQueueReusableCell:(UIView *)cell {
    [self.reusableCells addObject:cell];
}

// 返回复用Cell
- (UIView *)dequeueReusableCell {
    UIView *cell = [self.reusableCells lastObject];
    if (cell) {
        [self.reusableCells removeLastObject];
    }
    return cell;
}

// 移除指定Cell
- (void)removeCellAtIndex:(NSInteger)index {
    UIView *cell = [self.cells objectAtIndex:index];
    if ((NSObject *)cell == [NSNull null]) {
        return;
    }

    [self addQueueReusableCell:cell];
    
    if (cell.superview) {
        [cell removeFromSuperview];
    }
    
    [self.cells replaceObjectAtIndex:index withObject:[NSNull null]];
}

// MARK: - 数据处理

// 刷新视图
- (void)reloadData {
    
    [self stopTimer];
    
    for (UIView *cell in self.cells) {
        if ([cell isKindOfClass:UIView.class]) {
            [cell removeFromSuperview];
        }
    }
    [self.cells removeAllObjects];
    [self.reusableCells removeAllObjects];
    
    _numberOfItems = 0;
    _showNumberOfItems = 0;
    _currentIndex = 0;
    _visibleRange = NSMakeRange(0, 0);
    
    // 设置总页数
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(numberOfItemsInRecycleView:)]) {
        
        self.numberOfItems = [self.dataSource numberOfItemsInRecycleView:self];
        
        if (self.canLoop) {
            self.showNumberOfItems = self.numberOfItems == 1 ? 1: [self.dataSource numberOfItemsInRecycleView:self] * 3;
        } else {
            self.showNumberOfItems = self.numberOfItems == 1 ? 1: [self.dataSource numberOfItemsInRecycleView:self];
        }
        
    }
    
    if (self.showNumberOfItems == 0) {
        return;
    }
    
    for (NSInteger index = 0; index < self.showNumberOfItems; index++) {
        [self.cells addObject:[NSNull null]];
    }
    
    // 获取Cell大小
    self.itemSize = self.superview ? self.superview.bounds.size : self.bounds.size;
    if (self.delegate && self.delegate && [self.delegate respondsToSelector:@selector(sizeForItemInRecycleView:)]) {
        self.itemSize = [self.delegate sizeForItemInRecycleView:self];
    }
    
    // 设置ScrollView
    switch (self.orientation) {
        case LCRecycleViewOrientationHorizontal:
        {
            
            // 有缩放时调整间距
            if (self.minScale != 1) {
                self.factSpacing = self.minSpacing - self.itemSize.width * (1 - self.minScale) / 2;
            } else {
                self.factSpacing = self.minSpacing;
            }
            
            self.scrollView.frame = CGRectMake(0, 0, (self.itemSize.width + self.factSpacing) * self.scrollNumber, self.itemSize.height);
            if (self.alignment == LCRecycleViewAlignmentLeft) {
                self.scrollView.center = CGPointMake(self.edgeInsets.left + CGRectGetMidX(self.scrollView.frame), CGRectGetMidY(self.bounds));
            } else if (self.alignment == LCRecycleViewAlignmentCenter) {
                self.scrollView.center = CGPointMake(CGRectGetMidX(self.bounds) + self.factSpacing / 2, CGRectGetMidY(self.bounds));
            } else {
                self.scrollView.center = CGPointMake(self.bounds.size.width - self.edgeInsets.right - CGRectGetMidX(self.scrollView.frame), CGRectGetMidY(self.bounds));
            }
            if (self.canLoop || self.alignment != LCRecycleViewAlignmentLeft) {
                self.scrollView.contentSize = CGSizeMake((self.itemSize.width + self.factSpacing) * self.showNumberOfItems, 0);
            } else {
                self.scrollView.contentSize = CGSizeMake((self.itemSize.width + self.factSpacing) * self.showNumberOfItems - self.factSpacing - (self.frame.size.width - CGRectGetMaxX(self.scrollView.frame)) + self.edgeInsets.right, 0);
            }
            
            if (self.numberOfItems > 1) {
                if (self.canLoop) {
                    // loop的起始点
                    [self.scrollView setContentOffset:CGPointMake((self.itemSize.width + self.factSpacing) * self.numberOfItems, 0) animated:NO];
                } else {
                    [self.scrollView setContentOffset:CGPointMake(0, 0) animated:NO];
                }
            }
            
            break;
        }
        case LCRecycleViewOrientationVertical:
        {
            
            // 有缩放时调整间距
            if (self.minScale != 1) {
                self.factSpacing = self.minSpacing - self.itemSize.height * (1 - self.minScale) / 2;
            } else {
                self.factSpacing = self.minSpacing;
            }
            
            self.scrollView.frame = CGRectMake(0, 0, self.itemSize.width, (self.itemSize.height + self.factSpacing) * self.scrollNumber);
            if (self.alignment == LCRecycleViewAlignmentLeft) {
                self.scrollView.center = CGPointMake(CGRectGetMidX(self.bounds), self.edgeInsets.top + CGRectGetMidY(self.scrollView.frame));
            } else if (self.alignment == LCRecycleViewAlignmentCenter) {
                self.scrollView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds) + self.factSpacing / 2);
            } else {
                self.scrollView.center = CGPointMake(CGRectGetMidX(self.bounds), self.bounds.size.height - self.edgeInsets.bottom - CGRectGetMidY(self.scrollView.frame));
            }
            if (self.canLoop || self.alignment != LCRecycleViewAlignmentLeft) {
                self.scrollView.contentSize = CGSizeMake(0, (self.itemSize.height + self.factSpacing) * self.showNumberOfItems);
            } else {
                self.scrollView.contentSize = CGSizeMake(0, (self.itemSize.height + self.factSpacing) * self.showNumberOfItems - self.factSpacing - (self.frame.size.height - CGRectGetMaxY(self.scrollView.frame)) + self.edgeInsets.bottom);
            }
            
            if (self.numberOfItems > 1) {
                if (self.canLoop) {
                    // loop的起始点
                    [self.scrollView setContentOffset:CGPointMake(0, (self.itemSize.height + self.factSpacing) * self.numberOfItems) animated:NO];
                } else {
                    [self.scrollView setContentOffset:CGPointMake(0, 0) animated:NO];
                }
            }
            
            break;
        }
        default:
            break;
    }

    self.scrollView.hitTestInsets = UIEdgeInsetsMake(-CGRectGetMinY(self.scrollView.frame), -CGRectGetMinX(self.scrollView.frame), CGRectGetMaxY(self.scrollView.frame) - CGRectGetMaxY(self.frame), CGRectGetMaxX(self.scrollView.frame) - CGRectGetMaxX(self.frame));
    
    [self layoutItemsAtContentOffset:self.scrollView.contentOffset];
    
    [self startTimer];
}

// 开启定时器
- (void)startTimer {
    if (self.numberOfItems > 1 && self.autoScroll) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:self.autoScrollTimeInterval target:self selector:@selector(scrollToNextItem) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    }
}

// 关闭定时器
- (void)stopTimer {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

// 滚动到下一个
- (void)scrollToNextItem {
    switch (self.orientation) {
        case LCRecycleViewOrientationHorizontal:
        {
            CGFloat x = self.scrollView.contentOffset.x + (self.itemSize.width + self.factSpacing);
            if (!self.canLoop) {
                x = x < 0 ? 0 : x;
                x = x > self.scrollView.contentSize.width - self.scrollView.frame.size.width ? self.scrollView.contentSize.width - self.scrollView.frame.size.width : x;
            }
            [self.scrollView setContentOffset:CGPointMake(x, 0) animated:YES];
            break;
        }
        case LCRecycleViewOrientationVertical:
        {
            CGFloat y = self.scrollView.contentOffset.y + (self.itemSize.height + self.factSpacing);
            if (!self.canLoop) {
                y = y < 0 ? 0 : y;
                y = y > self.scrollView.contentSize.width - self.scrollView.frame.size.width ? self.scrollView.contentSize.width - self.scrollView.frame.size.width : y;
            }
            [self.scrollView setContentOffset:CGPointMake(0, y) animated:YES];
            break;
        }
        default:
            break;
    }
}

// 滚动到指定的Cell
- (void)scrollToItemAtIndex:(NSInteger)index animated:(BOOL)animated {
    switch (self.orientation) {
        case LCRecycleViewOrientationHorizontal:
        {
            CGFloat x = index * (self.itemSize.width + self.factSpacing);
            if (self.canLoop) {
                if (x <= (self.itemSize.width + self.factSpacing) * self.numberOfItems) {
                    x += (self.itemSize.width + self.factSpacing) * self.numberOfItems;
                }
            } else {
                x = x < 0 ? 0 : x;
                x = x > self.scrollView.contentSize.width - self.scrollView.frame.size.width ? self.scrollView.contentSize.width - self.scrollView.frame.size.width : x;
            }
            [self.scrollView setContentOffset:CGPointMake(x, 0) animated:animated];
            break;
        }
        case LCRecycleViewOrientationVertical:
        {
            CGFloat y = index * (self.itemSize.height + self.factSpacing);
            if (self.canLoop) {
                if (y <= (self.itemSize.height + self.factSpacing) * self.numberOfItems) {
                    y += (self.itemSize.height + self.factSpacing) * self.numberOfItems;
                }
            } else {
                y = y < 0 ? 0 : y;
                y = y > self.scrollView.contentSize.width - self.scrollView.frame.size.width ? self.scrollView.contentSize.width - self.scrollView.frame.size.width : y;
            }
            [self.scrollView setContentOffset:CGPointMake(0, y) animated:animated];
            break;
        }
        default:
            break;
    }
}

// 根据当前偏移量更新Cell
- (void)layoutItemsAtContentOffset:(CGPoint)offset {
    
    CGPoint startPoint = CGPointMake(offset.x - self.scrollView.frame.origin.x, offset.y - self.scrollView.frame.origin.y);
    CGPoint endPoint = CGPointMake(startPoint.x + self.bounds.size.width, startPoint.y + self.bounds.size.height);
    
    switch (self.orientation) {
        case LCRecycleViewOrientationHorizontal:
        {
            
            NSInteger startIndex = 0;
            for (int i = 0; i < self.cells.count; i++) {
                if ((self.itemSize.width + self.factSpacing) * (i + 1) > startPoint.x) {
                    startIndex = i;
                    break;
                }
            }
            
            NSInteger endIndex = startIndex;
            for (NSInteger i = startIndex; i < self.cells.count; i++) {
                //如果都不超过则取最后一个
                if (((self.itemSize.width + self.factSpacing) * (i + 1) < endPoint.x && (self.itemSize.width + self.factSpacing) * (i + 2) >= endPoint.x) || i + 2 == self.cells.count) {
                    endIndex = i + 1;//i+2 是以个数，所以其index需要减去1
                    break;
                }
            }
            
            //可见页分别向前向后扩展一个，提高效率
            startIndex = MAX(startIndex - 1, 0);
            endIndex = MIN(endIndex + 1, self.cells.count - 1);
            
            self.visibleRange = NSMakeRange(startIndex, endIndex - startIndex + 1);
            
            for (NSInteger i = startIndex; i <= endIndex; i++) {
                [self layoutItemAtIndex:i];
            }
            
            for (int i = 0; i < startIndex; i ++) {
                [self removeCellAtIndex:i];
            }
            
            for (NSInteger i = endIndex + 1; i < self.cells.count; i ++) {
                [self removeCellAtIndex:i];
            }
            
            break;
        }
        case LCRecycleViewOrientationVertical:
        {
            
            NSInteger startIndex = 0;
            for (int i = 0; i < self.cells.count; i++) {
                if ((self.itemSize.height + self.factSpacing) * (i + 1) > startPoint.y) {
                    startIndex = i;
                    break;
                }
            }
            
            NSInteger endIndex = startIndex;
            for (NSInteger i = startIndex; i < self.cells.count; i++) {
                //如果都不超过则取最后一个
                if (((self.itemSize.height + self.factSpacing) * (i + 1) < endPoint.y && (self.itemSize.height + self.factSpacing) * (i + 2) >= endPoint.y) || i + 2 == self.cells.count) {
                    endIndex = i + 1;//i+2 是以个数，所以其index需要减去1
                    break;
                }
            }
            
            //可见页分别向前向后扩展一个，提高效率
            startIndex = MAX(startIndex - 1, 0);
            endIndex = MIN(endIndex + 1, self.cells.count - 1);
            
            self.visibleRange = NSMakeRange(startIndex, endIndex - startIndex + 1);
            
            for (NSInteger i = startIndex; i <= endIndex; i++) {
                [self layoutItemAtIndex:i];
            }
            
            for (NSInteger i = 0; i < startIndex; i ++) {
                [self removeCellAtIndex:i];
            }
            
            for (NSInteger i = endIndex + 1; i < self.cells.count; i ++) {
                [self removeCellAtIndex:i];
            }
            
            break;
        }
        default:
            break;
    }
    
    [self refreshVisibleCellAppearance];
}

// 设置指定的Cell
- (void)layoutItemAtIndex:(NSInteger)index {
    
    NSParameterAssert(index >= 0 && index < self.cells.count);
    
    UIView *cell = [self.cells objectAtIndex:index];
    if ((NSObject *)cell != [NSNull null]) {
        return;
    }
    
    cell = [self.dataSource recycleView:self cellForItemAtIndex:index % self.numberOfItems];
    NSAssert(cell!=nil, @"datasource must not return nil");
    [self.cells replaceObjectAtIndex:index withObject:cell];
    
    cell.userInteractionEnabled = YES;
    cell.tag = index % self.numberOfItems;
    
    switch (self.orientation) {
        case LCRecycleViewOrientationHorizontal:
            cell.frame = CGRectMake((self.itemSize.width + self.factSpacing) * index, 0, self.itemSize.width, self.itemSize.height);
            break;
        case LCRecycleViewOrientationVertical:
            cell.frame = CGRectMake(0, (self.itemSize.height + self.factSpacing) * index, self.itemSize.width, self.itemSize.height);
            break;
        default:
            break;
    }
    
    if (!cell.superview) {
        [self.scrollView addSubview:cell];
    }
    
}

// 更新可见Cell的状态
- (void)refreshVisibleCellAppearance {

    //没有动效时无需更新
    if (self.minScale == 1 && self.minAlpha == 1) {
        return;
    }
    
    // 一页的宽度 包含间距
    CGFloat itemWidth = (self.itemSize.width + self.factSpacing);
    // 一页的高度 包含间距
    CGFloat itemHeight = (self.itemSize.height + self.factSpacing);
    // 最小宽度差
    CGFloat maxOffsetWidth = itemWidth * (1 - self.minScale);
    // 最小高度差
    CGFloat maxOffsetHeight = itemHeight * (1 - self.minScale);
    
    switch (self.orientation) {
        case LCRecycleViewOrientationHorizontal:
        {
            
            for (NSInteger i = self.visibleRange.location; i < self.visibleRange.location + self.visibleRange.length; i++) {
                
                UIView *cell = [self.cells objectAtIndex:i];
                CGFloat delta = fabs(cell.frame.origin.x - self.scrollView.contentOffset.x);
                // 原位置
                CGRect originCellFrame = CGRectMake(itemWidth * i, 0, self.itemSize.width, self.itemSize.height);
                // 高度差
                CGFloat offsetHeight;
                // 宽度差
                CGFloat offsetWidth;
                
                if (delta < itemWidth) {
                    offsetWidth = (1 - self.minScale) * delta;
                    offsetHeight = offsetWidth / itemWidth * itemHeight;
                } else {
                    offsetWidth = maxOffsetWidth;
                    offsetHeight = maxOffsetHeight;
                }
                
                cell.layer.transform = CATransform3DMakeScale((itemWidth - offsetWidth) / itemWidth, (itemHeight-offsetHeight) / itemHeight, 1.0);
                cell.frame = UIEdgeInsetsInsetRect(originCellFrame, UIEdgeInsetsMake(offsetHeight / 2, offsetWidth / 2, offsetHeight / 2, offsetWidth / 2));
                
                CGFloat scale = delta / itemWidth;
                if (scale > 1) {
                    scale = 1;
                }//0-1 0-0.3 1-0.7 1-0.3
                cell.alpha = 1 - (scale * (1 - self.minAlpha));
                
            }
            break;
        }
        case LCRecycleViewOrientationVertical:
        {
            
            for (NSInteger i = self.visibleRange.location; i < self.visibleRange.location + self.visibleRange.length; i++) {
                
                UIView *cell = [self.cells objectAtIndex:i];
                CGFloat delta = fabs(cell.frame.origin.y - self.scrollView.contentOffset.y);
                // 原位置
                CGRect originCellFrame = CGRectMake(0, itemHeight * i, self.itemSize.width, self.itemSize.height);
                // 高度差
                CGFloat offsetHeight;
                // 宽度差
                CGFloat offsetWidth;
                
                if (delta < itemHeight) {
                    offsetHeight = (1 - self.minScale) * delta;
                    offsetWidth = offsetHeight / itemHeight * itemWidth;
                } else {
                    offsetHeight = maxOffsetHeight;
                    offsetWidth = maxOffsetWidth;
                }
                
                cell.layer.transform = CATransform3DMakeScale((itemWidth - offsetWidth) / itemWidth, (itemHeight - offsetHeight) / itemHeight, 1.0);
                cell.frame = UIEdgeInsetsInsetRect(originCellFrame, UIEdgeInsetsMake(offsetHeight / 2, offsetWidth / 2, offsetHeight / 2, offsetWidth / 2));
                
                CGFloat scale = delta / itemHeight;
                if (scale > 1) {
                    scale = 1;
                }//0-1 0-0.3 1-0.7 1-0.3
                cell.alpha = 1 - (scale * (1 - self.minAlpha));
                
            }
        }
        default:
            break;
    }
    
}

// MARK: - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    if (self.numberOfItems == 0) {
        return;
    }
    
    if (self.canLoop && self.numberOfItems > 1) {
        
        switch (self.orientation) {
            case LCRecycleViewOrientationHorizontal:
            {
                
                if (scrollView.contentOffset.x >= (self.itemSize.width + self.factSpacing) * self.numberOfItems * 2) {
                    [scrollView setContentOffset:CGPointMake((self.itemSize.width + self.factSpacing) * self.numberOfItems, 0) animated:NO];
                }
                if (scrollView.contentOffset.x <= (self.itemSize.width + self.factSpacing) * (self.numberOfItems - 1)) {
                    [scrollView setContentOffset:CGPointMake((self.itemSize.width + self.factSpacing) * (2 * self.numberOfItems - 1), 0) animated:NO];
                }
                
                break;
            }
            case LCRecycleViewOrientationVertical:
            {
                
                if (scrollView.contentOffset.y >= (self.itemSize.height + self.factSpacing) * self.numberOfItems * 2) {
                    [scrollView setContentOffset:CGPointMake(0, (self.itemSize.height + self.factSpacing) * self.numberOfItems) animated:NO];
                }
                if (scrollView.contentOffset.y <= (self.itemSize.height + self.factSpacing) * (self.numberOfItems - 1)) {
                    [scrollView setContentOffset:CGPointMake(0, (self.itemSize.height + self.factSpacing) * (2 * self.numberOfItems - 1)) animated:NO];
                }
                
                break;
            }
            default:
                break;
        }
        
    }
    
    [self layoutItemsAtContentOffset:scrollView.contentOffset];
    
    NSInteger index;
    switch (self.orientation) {
        case LCRecycleViewOrientationHorizontal:
        {
            index = (int)round(scrollView.contentOffset.x / (self.itemSize.width + self.factSpacing)) % self.numberOfItems;
            if (self.canLoop) {
                if (self.numberOfItems <= 1) {
                    index = 0;
                }
            } else {
                if (scrollView.contentOffset.x >= scrollView.contentSize.width - scrollView.frame.size.width) {
                    index = self.numberOfItems - 1;
                }
            }
            break;
        }
        case LCRecycleViewOrientationVertical:
        {
            index = (int)round(scrollView.contentOffset.y / (self.itemSize.height + self.factSpacing)) % self.numberOfItems;
            if (self.canLoop) {
                if (self.numberOfItems <= 1) {
                    index = 0;
                }
            } else {
                if (scrollView.contentOffset.y >= scrollView.contentSize.height - scrollView.frame.size.height) {
                    index = self.numberOfItems - 1;
                }
            }
            break;
        }
        default:
            break;
    }
    
    if (_currentIndex != index && index >= 0) {
        self.currentIndex = index;
    }
    
    if ([self.delegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
        [self.delegate scrollViewDidScroll:scrollView];
    }
    
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self stopTimer];
    if ([self.delegate respondsToSelector:@selector(scrollViewWillBeginDragging:)]) {
        [self.delegate scrollViewWillBeginDragging:scrollView];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self startTimer];
    if ([self.delegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
        [self.delegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    if ([self.delegate respondsToSelector:@selector(scrollViewWillBeginDecelerating:)]) {
        [self.delegate scrollViewWillBeginDecelerating:scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if ([self.delegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
        [self.delegate scrollViewDidEndDecelerating:scrollView];
    }
}

// MARK: UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

// MARK: LCPageControlDelegate
- (void)pageControlDidSelect:(UIView<LCPageControlDelegate> *)pageControl atPage:(NSInteger)currentPage {
    [self scrollToItemAtIndex:currentPage animated:YES];
}

@end

//
//  RecycleView.swift
//  RecycleView
//
//  Created by lax on 2022/8/23.
//

import UIKit
import SnapKit

public protocol RecycleViewDelegate: UIScrollViewDelegate {

    /// 点击cell
    func recycleView(_ recycleView: RecycleView, didSelectRowAt index: Int)
    
}

public extension RecycleViewDelegate {
    
    func recycleView(_ recycleView: RecycleView, didSelectRowAt index: Int) {}
    
}

public protocol RecycleViewDelegateFlowlayout: RecycleViewDelegate {
    
    /// 返回cell的大小
    func sizeForItemInRecycleView(_ recycleView: RecycleView) -> CGSize
    
    /// 返回滚动方向
    func orientationForRecycleView(_ recycleView: RecycleView) -> RecycleView.Orientation?
    
    /// 返回当前卡片的位置
    func alignmentForRecycleView(_ recycleView: RecycleView) -> RecycleView.Alignment?
    
}

public extension RecycleViewDelegateFlowlayout {
    
    func sizeForItemInRecycleView(_ recycleView: RecycleView) -> CGSize { return CGSize() }
    
    func orientationForRecycleView(_ recycleView: RecycleView) -> RecycleView.Orientation? { return nil }
    
    func alignmentForRecycleView(_ recycleView: RecycleView) -> RecycleView.Alignment? { return nil }
    
}

public protocol RecycleViewDataSource: NSObjectProtocol {

    /// 返回Cell的数量
    func numberOfItemsInRecycleView(_ recycleView: RecycleView) -> Int

    /// 返回Cell样式
    func recycleView(_ recycleView: RecycleView, cellForItemAt index: Int) -> UIView?

}

extension RecycleView {
    
    public enum Orientation {
        /// 横向
        case horizontal
        /// 竖向
        case vertical
    }

    public enum Alignment {
        /// 居左
        case left
        /// 居中
        case center
        /// 居右
        case right
    }
    
}

open class RecycleView: UIView {
    
    weak open var delegate: RecycleViewDelegate?

    /// 数据源
    weak open var dataSource: RecycleViewDataSource?

    /// 滚动视图
    private(set) lazy var scrollView: RecycleScrollView = {
        let scrollView = RecycleScrollView()
        scrollView.delegate = self
        scrollView.scrollsToTop = false
        scrollView.clipsToBounds = false
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    /// 总页数
    open var numberOfItems = 0 {
        didSet {
            pageControl?.recyclePageControlSetNumberOfPages(numberOfItems)
        }
    }

    /// 当前页数
    open var currentIndex = 0 {
        didSet {
            if !canLoop && currentIndex == numberOfItems - 1 && Int(frame.size.width) % Int(itemSize.width + minSpacing) > Int(itemSize.width / 2) {
                scrollView.isPagingEnabled = false
            } else {
                scrollView.isPagingEnabled = true
            }
            pageControl?.recyclePageControlSetCurrentPage(currentIndex)
        }
    }

    /// 一页的大小
    open var itemSize = CGSize()

    /// 滚动方向 默认横向
    open var orientation: Orientation = .horizontal

    /// 当前卡片的位置 默认居左
    open var alignment: Alignment = .left

    /// 是否开启无限轮播 默认false
    open var canLoop = false

    /// 是否开启自动滚动 默认false
    open var autoScroll = false

    /// 自动切换视图的时间 默认5s
    open var autoScrollTimeInterval: TimeInterval = 5

    /// 一次滑动的页数 默认1
    open var scrollNumber = 1

    /// 内边距 默认0
    open var edgeInsets = UIEdgeInsets()

    /// 最小Cell的间距 默认0
    open var minSpacing: CGFloat = 0

    /// 最小Cell的比例 默认1
    open var minScale: CGFloat = 1

    /// 最小Cell的透明度 默认1
    open var minAlpha: CGFloat = 1

    /// 指示器
    open var pageControl: (UIPageControl & RecyclePageControlProtocol)? {
        didSet {
            guard let view = pageControl else { return }
            addSubview(view)
            layoutPageControl()
            pageControl?.recyclePageControlSetCurrentPage(currentIndex)
        }
    }

    /// 调整指示器的位置(Top无效 pageControl以bottom和height设置约束)
    open var pageControlEdgeInsets = UIEdgeInsets() {
        didSet {
            layoutPageControl()
        }
    }
    
    /// 定时器
    private var timer: Timer?
    
    /// 需要显示的总页数
    private var showNumberOfItems = 0

    /// 实际设置的Cell间距(受minScale影响)
    private var factSpacing: CGFloat = 0

    /// 可见Cell的范围
    private var visibleRange = NSRange()

    /// Cell数组
    private var cells: [NSObject] = []

    /// 可复用Cell数组
    private var reusableCells: [UIView] = []
    
    private func layoutPageControl() {
        guard let _ = pageControl?.superview else { return }
        switch orientation {
        case .horizontal:
            pageControl?.snp.remakeConstraints({ make in
                make.left.equalTo(pageControlEdgeInsets.left)
                make.right.equalTo(-pageControlEdgeInsets.right)
                make.bottom.equalTo(-pageControlEdgeInsets.bottom)
            })
            break;
        case .vertical:
            pageControl?.snp.remakeConstraints({ make in
                make.left.equalTo(pageControlEdgeInsets.left)
                make.top.equalTo(pageControlEdgeInsets.top)
                make.bottom.equalTo(-pageControlEdgeInsets.bottom)
            })
            break;
        }
    }
    
    // MARK: - 系统方法
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func initView() {
        clipsToBounds = true
        
        orientation = .horizontal;
        alignment = .left;
        
        canLoop = false
        autoScroll = false
        autoScrollTimeInterval = 5.0;
        
        scrollNumber = 1;
        factSpacing = 0;
        minAlpha = 1;
        minScale = 1;
            
        addSubview(scrollView)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        reloadData()
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with:event)
        var view = touches.first?.view
        while view != nil {
            if let v = view, cells.contains(v), let index = cells.firstIndex(of: v) {
                delegate?.recycleView(self, didSelectRowAt: index % numberOfItems)
                break
            }
            view = view?.superview
        }
    }
    
    /// 解决当父View释放时，当前视图因为被Timer强引用而不能释放的问题
    open override func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview == nil {
            stopTimer()
        }
    }

    /// 解决当timer释放后 回调scrollViewDidScroll时访问野指针导致崩溃
    deinit {
        scrollView.delegate = nil;
    }
    
    // MARK: - Cell复用

    /// 添加复用Cell
    open func addQueueReusableCell(_ cell: UIView) {
        reusableCells.append(cell)
    }

    /// 获取可重复使用的Cell
    open func dequeueReusableCell() -> UIView? {
        let cell = reusableCells.last
        if let _ = cell {
            reusableCells.removeLast()
        }
        return cell
    }

    /// 移除指定Cell
    open func removeCellAtIndex(_ index: Int) {
        if !(0..<cells.count).contains(index) { return }
        if let cell = cells[index] as? UIView {
            addQueueReusableCell(cell)
            if let _ = cell.superview {
                cell.removeFromSuperview()
            }
        }
        cells[index] = NSNull()
    }
    
    // MARK: - 数据处理

    /// 刷新视图
    open func reloadData() {
        stopTimer()
        
        for cell in cells {
            if let cell = cell as? UIView {
                cell.removeFromSuperview()
            }
        }
        cells.removeAll()
        reusableCells.removeAll()
        
        currentIndex = 0
        visibleRange = NSRange()
        
        numberOfItems = dataSource?.numberOfItemsInRecycleView(self) ?? 0
        if canLoop {
            showNumberOfItems = numberOfItems == 1 ? 1 : numberOfItems * 3
        } else {
            showNumberOfItems = numberOfItems == 1 ? 1 : numberOfItems
        }
        
        if showNumberOfItems == 0 {
            return;
        }
        
        for _ in 0..<showNumberOfItems {
            cells.append(NSNull())
        }
        
        itemSize = CGSize()
        if let delegate = delegate as? RecycleViewDelegateFlowlayout {
            itemSize = delegate.sizeForItemInRecycleView(self)
            if let orientation = delegate.orientationForRecycleView(self) {
                self.orientation = orientation
            }
            if let alignment = delegate.alignmentForRecycleView(self) {
                self.alignment = alignment
            }
        }
        
        switch orientation {
        case .horizontal:
            
            if minScale == 1 {
                factSpacing = minSpacing
            } else {
                factSpacing = minSpacing - itemSize.width * (1 - minScale) / 2
            }
            
            scrollView.frame = CGRect(x: 0, y: 0, width: (itemSize.width + factSpacing) * CGFloat(scrollNumber), height: itemSize.height)
            switch alignment {
            case .left:
                scrollView.center = CGPoint(x: edgeInsets.left + scrollView.frame.midX, y: bounds.midY)
            case .center:
                scrollView.center = CGPoint(x: bounds.midX + factSpacing / 2, y: bounds.midY)
            case .right:
                scrollView.center = CGPoint(x: bounds.size.width - edgeInsets.right - scrollView.frame.midX, y: bounds.midY)
            }
            
            if canLoop || alignment != .left {
                scrollView.contentSize = CGSize(width: (itemSize.width + factSpacing) * CGFloat(showNumberOfItems), height: 0)
            } else {
                scrollView.contentSize = CGSize(width: (itemSize.width + factSpacing) * CGFloat(showNumberOfItems) - factSpacing - (frame.size.width - scrollView.frame.maxX) + edgeInsets.right, height: 0)
            }
            
            if numberOfItems > 1 {
                if canLoop {
                    scrollView.setContentOffset(CGPoint(x: (itemSize.width + factSpacing) * CGFloat(numberOfItems), y: 0), animated: false)
                } else {
                    scrollView.setContentOffset(CGPoint(), animated: false)
                }
            }
            break
            
        case .vertical:
            
            if minScale == 1 {
                factSpacing = minSpacing
            } else {
                factSpacing = minSpacing - itemSize.height * (1 - minScale) / 2
            }
            
            scrollView.frame = CGRect(x: 0, y: 0, width: itemSize.width, height: (itemSize.height + factSpacing) * CGFloat(scrollNumber))
            switch alignment {
            case .left:
                scrollView.center = CGPoint(x: bounds.midX, y: edgeInsets.top + scrollView.frame.midY)
            case .center:
                scrollView.center = CGPoint(x: bounds.midX, y: bounds.midY + factSpacing / 2)
            case .right:
                scrollView.center = CGPoint(x: bounds.midX, y: bounds.size.height - edgeInsets.bottom - scrollView.frame.midY)
            }
            
            if canLoop || alignment != .left {
                scrollView.contentSize = CGSize(width: 0, height: (itemSize.height + factSpacing) * CGFloat(showNumberOfItems))
            } else {
                scrollView.contentSize = CGSize(width: 0, height: (itemSize.height + factSpacing) * CGFloat(showNumberOfItems) - factSpacing - (frame.size.height - scrollView.frame.maxY) + edgeInsets.bottom)
            }
            
            if numberOfItems > 1 {
                if canLoop {
                    scrollView.setContentOffset(CGPoint(x: 0, y: (itemSize.height + factSpacing) * CGFloat(numberOfItems)), animated: false)
                } else {
                    scrollView.setContentOffset(CGPoint(), animated: false)
                }
            }
            break
            
        }
        
        scrollView.hitTestInsets = UIEdgeInsets(top: -scrollView.frame.minY, left: scrollView.frame.minX, bottom: scrollView.frame.maxY - frame.maxY, right: scrollView.frame.maxX - frame.maxX)
        layoutItemsAtContentOffset(offset: scrollView.contentOffset)
        startTimer()
        
    }
    
    private func startTimer() {
        if numberOfItems > 1 && autoScroll {
            timer = Timer(timeInterval: autoScrollTimeInterval, target: self, selector: #selector(scrollToNextItem), userInfo: nil, repeats: true)
            if let timer = timer {
                RunLoop.main.add(timer, forMode: .common)
            }
        }
    }

    private func stopTimer() {
        if let _ = timer {
            timer?.invalidate()
            timer = nil
        }
    }

    /// 滚动到下一个
    @objc open func scrollToNextItem() {
        switch orientation {
        case .horizontal:
            var x = scrollView.contentOffset.x + itemSize.width + factSpacing
            if !canLoop {
                x = max(x, 0)
                x = min(x, scrollView.contentSize.width - scrollView.frame.size.width)
            }
            scrollView.setContentOffset(CGPoint(x: x, y: 0), animated: true)
            break
        case .vertical:
            var y = scrollView.contentOffset.y + itemSize.height + factSpacing
            if !canLoop {
                y = max(y, 0)
                y = min(y, scrollView.contentSize.width - scrollView.frame.size.width)
            }
            scrollView.setContentOffset(CGPoint(x: 0, y: y), animated: true)
            break
        }
    }

    /// 滚动到指定的位置
    /// @param index 下标
    /// @param animated 动画
    open func scrollToItem(at index: Int, animated: Bool) {
        switch orientation {
        case .horizontal:
            var x = (itemSize.width + factSpacing) * CGFloat(index)
            if canLoop {
                if x <= (itemSize.width + factSpacing) * CGFloat(numberOfItems) {
                    x += (itemSize.width + factSpacing) * CGFloat(numberOfItems)
                }
            } else {
                x = max(x, 0)
                x = min(x, scrollView.contentSize.width - scrollView.frame.size.width)
            }
            scrollView.setContentOffset(CGPoint(x: x, y: 0), animated: true)
            break
        case .vertical:
            var y = (itemSize.height + factSpacing) * CGFloat(index)
            if canLoop {
                if y <= (itemSize.height + factSpacing) * CGFloat(numberOfItems) {
                    y += (itemSize.height + factSpacing) * CGFloat(numberOfItems)
                }
            } else {
                y = max(y, 0)
                y = min(y, scrollView.contentSize.width - scrollView.frame.size.width)
            }
            scrollView.setContentOffset(CGPoint(x: 0, y: y), animated: true)
            break
        }
    }
    
    
    /// 根据当前偏移量更新Cell
    private func layoutItemsAtContentOffset(offset: CGPoint) {
        
        let startPoint = CGPoint(x: offset.x - scrollView.frame.origin.x, y: offset.y - scrollView.frame.origin.y)
        let endPoint = CGPoint(x: startPoint.x + frame.size.width, y: startPoint.y + frame.size.height)
        var startIndex = 0
        var endIndex = 0
        
        switch orientation {
        case .horizontal:
            for i in 0..<cells.count {
                if (itemSize.width + factSpacing) * CGFloat(i + 1) > startPoint.x {
                    startIndex = i
                    break
                }
            }
            endIndex = startIndex
            for i in startIndex..<cells.count {
                if ((itemSize.width + factSpacing) * CGFloat(i + 1) < endPoint.x && (itemSize.width + factSpacing) * CGFloat(i + 2) >= endPoint.x) || i + 2 == cells.count {
                    endIndex = i + 1
                    break
                }
            }
            break
        case .vertical:
            for i in 0..<cells.count {
                if (itemSize.height + factSpacing) * CGFloat(i + 1) > startPoint.y {
                    startIndex = i
                    break
                }
            }
            endIndex = startIndex
            for i in startIndex..<cells.count {
                if ((itemSize.height + factSpacing) * CGFloat(i + 1) < endPoint.y && (itemSize.height + factSpacing) * CGFloat(i + 2) >= endPoint.y) || i + 2 == cells.count {
                    endIndex = i + 1
                    break
                }
            }
            break
        }
        
        startIndex = max(startIndex - 1, 0)
        endIndex = min(endIndex + 1, cells.count - 1)
        visibleRange = NSRange(location: startIndex, length: endIndex - startIndex + 1)
        
        for i in startIndex...endIndex {
            layoutItemAtIndex(index: i)
        }
        for i in 0..<startIndex {
            removeCellAtIndex(i)
        }
        for i in endIndex + 1..<cells.count {
            removeCellAtIndex(i)
        }
        refreshVisibleCellAppearance()
        
    }

    /// 设置指定的Cell
    private func layoutItemAtIndex(index: Int) {
        
        if !(0..<cells.count).contains(index) {
            return
        }
        
        if !(cells[index] is NSNull) {
            return
        }
        
        let cell = dataSource?.recycleView(self, cellForItemAt: index % numberOfItems)
        if let cell = cell {
            cell.isUserInteractionEnabled = true
            cell.tag = index % numberOfItems
            cells[index] = cell
        }
        
        guard let cell = cell else {
            return
        }
        
        switch orientation {
        case .horizontal:
            cell.frame = CGRect(x: (itemSize.width + factSpacing) * CGFloat(index), y: 0, width: itemSize.width, height: itemSize.height)
            break
        case .vertical:
            cell.frame = CGRect(x: 0, y: (itemSize.height + factSpacing) * CGFloat(index), width: itemSize.width, height: itemSize.height)
            break
        }
        if cell.superview == nil {
            scrollView.addSubview(cell)
        }
        
    }

    /// 更新可见Cell的状态
    private func refreshVisibleCellAppearance() {
        
        if minScale == 1 && minAlpha == 1 {
            return
        }
        
        // 一页的宽度 包含间距
        let itemWidth = (itemSize.width + factSpacing)
        // 一页的高度 包含间距
        let itemHeight = (itemSize.height + factSpacing)
        // 最小宽度差
        let maxOffsetWidth = itemWidth * (1 - minScale)
        // 最小高度差
        let maxOffsetHeight = itemHeight * (1 - minScale)
        
        for i in visibleRange.location..<visibleRange.location + visibleRange.length {
            if let cell = cells[i] as? UIView {
                
                let delta: CGFloat
                // 原位置
                let originCellFrame: CGRect
                // 宽度差
                let offsetWidth: CGFloat
                // 高度差
                let offsetHeight: CGFloat
                
                switch orientation {
                case .horizontal:
                    
                    delta = abs(cell.frame.origin.x - scrollView.contentOffset.x)
                    originCellFrame = CGRect(x: itemWidth * CGFloat(i), y: 0, width: itemSize.width, height: itemSize.height)
                    if delta < itemWidth {
                        offsetWidth = (1 - minScale) * delta
                        offsetHeight = offsetWidth / itemWidth * itemHeight
                    } else {
                        offsetWidth = maxOffsetWidth
                        offsetHeight = maxOffsetHeight
                    }
                    break
                    
                case .vertical:
                    
                    delta = abs(cell.frame.origin.y - scrollView.contentOffset.y)
                    originCellFrame = CGRect(x: 0, y: itemHeight * CGFloat(i), width: itemSize.width, height: itemSize.height)
                    if delta < itemHeight {
                        offsetHeight = (1 - minScale) * delta
                        offsetWidth = offsetHeight / itemHeight * itemWidth
                    } else {
                        offsetWidth = maxOffsetWidth
                        offsetHeight = maxOffsetHeight
                    }
                    break
                }
                
                cell.layer.transform = CATransform3DMakeScale((itemWidth - offsetWidth) / itemWidth, (itemHeight - offsetHeight) / itemHeight, 1.0)
                cell.frame = originCellFrame.inset(by: UIEdgeInsets(top: offsetHeight / 2, left: offsetWidth / 2, bottom: offsetHeight / 2, right: offsetWidth / 2))
                
                var scale = delta / itemWidth
                scale = min(scale, 1)// 0-1 0-0.3 1-0.7 1-0.3
                cell.alpha = 1 - (scale * (1 - minAlpha))
                
            }
        }
        
    }
    
}

extension RecycleView: UIScrollViewDelegate {
    
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if numberOfItems == 0 {
            return
        }
        
        if canLoop && numberOfItems > 1 {
            switch orientation {
            case .horizontal:
                if scrollView.contentOffset.x >= (itemSize.width + factSpacing) * CGFloat(numberOfItems) * 2 {
                    scrollView.setContentOffset(CGPoint(x: (itemSize.width + factSpacing) * CGFloat(numberOfItems), y: 0), animated: false)
                }
                if scrollView.contentOffset.x <= (itemSize.width + factSpacing) * CGFloat(numberOfItems - 1) {
                    scrollView.setContentOffset(CGPoint(x: (itemSize.width + factSpacing) * CGFloat(numberOfItems * 2 - 1), y: 0), animated: false)
                }
                break
            case .vertical:
                if scrollView.contentOffset.y >= (itemSize.height + factSpacing) * CGFloat(numberOfItems * 2) {
                    scrollView.setContentOffset(CGPoint(x: 0, y: (itemSize.height + factSpacing) * CGFloat(numberOfItems)), animated: false)
                }
                if scrollView.contentOffset.y <= (itemSize.height + factSpacing) * CGFloat(numberOfItems - 1) {
                    scrollView.setContentOffset(CGPoint(x: 0, y: (itemSize.height + factSpacing) * CGFloat(numberOfItems * 2 - 1)), animated: false)
                }
                break
            }
        }
        
        layoutItemsAtContentOffset(offset: scrollView.contentOffset)
        
        var index: Int
        switch orientation {
        case .horizontal:
            index = Int(round(scrollView.contentOffset.x / (itemSize.width + factSpacing))) % numberOfItems
            if canLoop {
                if numberOfItems <= 1 {
                    index = 0
                }
            } else {
                if scrollView.contentOffset.x >= scrollView.contentSize.width - scrollView.frame.size.width {
                    index = numberOfItems - 1
                }
            }
            break
        case .vertical:
            index = Int(round(scrollView.contentOffset.y / (itemSize.height + factSpacing))) % numberOfItems
            if canLoop {
                if numberOfItems <= 1 {
                    index = 0
                }
            } else {
                if scrollView.contentOffset.y >= scrollView.contentSize.height - scrollView.frame.size.height {
                    index = numberOfItems - 1
                }
            }
            break
        }
        
        if currentIndex != index && index >= 0 {
            currentIndex = index
        }
        
        delegate?.scrollViewDidScroll?(scrollView)
        
    }
    
    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        stopTimer()
        delegate?.scrollViewWillBeginDragging?(scrollView)
    }
    
    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        startTimer()
        delegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }
    
    open func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        delegate?.scrollViewWillBeginDecelerating?(scrollView)
    }
    
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        delegate?.scrollViewDidEndDecelerating?(scrollView)
    }
    
}

extension RecycleView: UIGestureRecognizerDelegate {
    
    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}

extension RecycleView: RecyclePageControlDelegate {
    
    open func pageControlDidSelect(pageControl: UIView, atPage currentPage: Int) {
        scrollToItem(at: currentPage, animated: true)
    }
    
}

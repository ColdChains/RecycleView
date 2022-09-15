//
//  PageControl.swift
//  RecycleView
//
//  Created by lax on 2022/9/13.
//

import UIKit

public protocol RecyclePageControlDelegate: NSObjectProtocol {

    /// 设置总页数
    func pageControlSetNumberOfPages(numberOfPages: Int)

    /// 设置当前页数
    func pageControlSetCurrentPage(currentPage: Int)

    /// 点击指示器
    func pageControlDidSelect(pageControl: UIView, atPage currentPage: Int)

}

public extension RecyclePageControlDelegate {
    
    func pageControlSetNumberOfPages(numberOfPages: Int) {}

    func pageControlSetCurrentPage(currentPage: Int) {}

    func pageControlDidSelect(pageControl: UIView, atPage currentPage: Int) {}
    
}

open class RecyclePageControl: UIPageControl {
    
    weak open var delegate: RecyclePageControlDelegate?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addTarget(self, action: #selector(pageControlValueChanged), for: .touchUpInside)
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    @objc private func pageControlValueChanged() {
        delegate?.pageControlDidSelect(pageControl: self, atPage: currentPage)
    }

}

extension RecyclePageControl: RecyclePageControlDelegate {
    
    public func pageControlSetNumberOfPages(numberOfPages: Int) {
        self.numberOfPages = numberOfPages
    }
    
    public func pageControlSetCurrentPage(currentPage: Int) {
        self.currentPage = currentPage
    }
    
    public func pageControlDidSelect(pageControl: UIView, atPage currentPage: Int) {
        self.currentPage = currentPage
    }
    
}

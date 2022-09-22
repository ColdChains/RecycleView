//
//  RecyclePageControlProtocol.swift
//  RecycleView
//
//  Created by lax on 2022/9/22.
//

import Foundation

public protocol RecyclePageControlProtocol: NSObjectProtocol {

    /// 设置总页数
    func recyclePageControlSetNumberOfPages(_ numberOfPages: Int)

    /// 设置当前页数
    func recyclePageControlSetCurrentPage(_ currentPage: Int)

}

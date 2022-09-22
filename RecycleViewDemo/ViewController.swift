//
//  ViewController.swift
//  RecycleViewDemo
//
//  Created by lax on 2022/8/23.
//

import UIKit
import SnapKit
import RecycleView

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 卡片效果
        let recycleView = RecycleView()
        recycleView.delegate = self
        recycleView.dataSource = self
        recycleView.edgeInsets = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
        recycleView.minSpacing = 12
        recycleView.canLoop = false
        recycleView.tag = 100
        
        view.addSubview(recycleView)
        recycleView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(88)
            make.height.equalTo(100)
        } 
        
        // 轮播图效果
        let bannerView = RecycleView()
        bannerView.delegate = self
        bannerView.dataSource = self
        bannerView.edgeInsets = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
        bannerView.minSpacing = 12
        bannerView.canLoop = true
        bannerView.autoScroll = true
        
        let control = RecyclePageControl()
        control.backgroundColor = .lightGray
        control.pageIndicatorTintColor = .red
        control.currentPageIndicatorTintColor = .white
        control.delegate = recycleView
        bannerView.pageControl = control
        
        view.addSubview(bannerView)
        bannerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(recycleView.snp.bottom).offset(44)
            make.height.equalTo(333)
        }
        
    }

}

extension ViewController: RecycleViewDelegateFlowlayout, RecycleViewDataSource {
    
    func numberOfItemsInRecycleView(_ recycleView: RecycleView) -> Int {
        return recycleView.tag == 100 ? 10 : 3
    }
    
    func recycleView(_ recycleView: RecycleView, cellForItemAt index: Int) -> UIView? {
        var cell = recycleView.dequeueReusableCell() as? UIImageView
        if cell == nil {
            cell = UIImageView()
        }
        cell?.backgroundColor = [UIColor.green, UIColor.orange, UIColor.red][index % 3]
        return cell
    }
    
    func recycleView(_ recycleView: RecycleView, didSelectRowAt index: Int) {
        print(index)
    }
    
    func sizeForItemInRecycleView(_ recycleView: RecycleView) -> CGSize {
        return recycleView.tag == 100 ? CGSize(width: 100, height: 100) : CGSize(width: UIScreen.main.bounds.size.width - 18 * 2, height: 333)
    }
    
}


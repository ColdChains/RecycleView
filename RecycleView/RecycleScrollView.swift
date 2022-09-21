//
//  RecycleScrollView.swift
//  RecycleView
//
//  Created by lax on 2022/8/23.
//

import UIKit

open class RecycleScrollView: UIScrollView {

    open var hitTestInsets: UIEdgeInsets = UIEdgeInsets()
    
    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        var rect = bounds;
        rect.origin.x += hitTestInsets.left
        rect.origin.y += hitTestInsets.top
        rect.size.width -= hitTestInsets.left + hitTestInsets.right
        rect.size.height -= hitTestInsets.top + hitTestInsets.bottom
        return rect.contains(point)
    }

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        next?.touchesBegan(touches, with: event)
        super.touchesBegan(touches, with: event)
    }

    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        next?.touchesMoved(touches, with: event)
        super.touchesMoved(touches, with: event)
    }

    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        next?.touchesEnded(touches, with: event)
        super.touchesEnded(touches, with: event)
    }

    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        next?.touchesCancelled(touches, with: event)
        super.touchesCancelled(touches, with: event)
    }

}

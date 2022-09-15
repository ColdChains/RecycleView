//
//  RecycleScrollView.swift
//  RecycleView
//
//  Created by lax on 2022/8/23.
//

import UIKit

class RecycleScrollView: UIScrollView {

    var hitTestInsets: UIEdgeInsets = UIEdgeInsets()
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        var rect = bounds;
        rect.origin.x += hitTestInsets.left
        rect.origin.y += hitTestInsets.top
        rect.size.width -= hitTestInsets.left + hitTestInsets.right
        rect.size.height -= hitTestInsets.top + hitTestInsets.bottom
        return rect.contains(point)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        next?.touchesBegan(touches, with: event)
        super.touchesBegan(touches, with: event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        next?.touchesMoved(touches, with: event)
        super.touchesMoved(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        next?.touchesEnded(touches, with: event)
        super.touchesEnded(touches, with: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        next?.touchesCancelled(touches, with: event)
        super.touchesCancelled(touches, with: event)
    }

}

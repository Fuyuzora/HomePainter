//
//  ThresholdPanGesture.swift
//  Home Painter
//
//  Created by Robert Wan on 2019-01-30.
//  Copyright © 2019 App. All rights reserved.
//

import Foundation
import UIKit.UIGestureRecognizerSubclass

class ThresholdPanGesture: UIPanGestureRecognizer {
    // Indicates where currently active gesture exceeds the limit
    private(set) var isThresholdExceeded = false
    
    // Observe when the state of "gesture" changes to reset the threshold
    override var state: UIGestureRecognizer.State {
        didSet {
            switch state {
            case .began, .changed:
                break
            default:
                isThresholdExceeded = false
            }
        }
    }
    
    // Returns the threshold value that should be used dependent on the number of touches
    private static func threshold(forTouchCount count: Int) -> CGFloat {
        switch count {
        case 1:
            return 30
        // Use a larger value for gesture with more than one finger, this give priority to other gestures
        default:
            return 60
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        
        let translationMagnitude = translation(in: view).length
        
        // Adjust threshold value based on the number of fingers used
        let threshold = ThresholdPanGesture.threshold(forTouchCount: touches.count)
        if !isThresholdExceeded && translationMagnitude > threshold {
            isThresholdExceeded = true
            
            // Set the overall translation to zero since the gesture should now begin
            setTranslation(.zero, in: view)
        }
    }
}

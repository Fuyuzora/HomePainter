//
//  StatusViewController.swift
//  Home Painter
//
//  Created by Robert Wan on 2019-01-27.
//  Copyright © 2019 App. All rights reserved.
//

import Foundation
import ARKit

// Displayed at the top of the device
// Indicates the current status of AR view
// Also allows user to reset the view

class StatusViewController: UIViewController {
    // Types
    enum MessageType {
        case trackingStateEscalation
        case planeEstimation
        case contentPlacement
        case focusSquare
        
        static var all: [MessageType] = [
            .trackingStateEscalation,
            .planeEstimation,
            .contentPlacement,
            .focusSquare,
        ]
    }
    
    // IBOutlets:
    @IBOutlet weak private var messagePanel: UIVisualEffectView!
    @IBOutlet weak private var messageLabel: UILabel!
    @IBOutlet weak private var restartExperienceButton: UIButton!
    
    // Properties
    // Triggered when restart button is pressed
    var restartButtonHandler:() -> Void = {}
    
    // seconds before the timer message fades out
    private let displayDuriation: TimeInterval = 6
    
    // Timer for hiding message
    private var messageHideTimer: Timer?
    private var timers: [MessageType: Timer] = [:]
    
    // Message Handling
    func showMessage(_ text: String){
        // cancel any previous hide timer
        messageHideTimer?.invalidate()
        
        messageLabel.text = text
        
    }
    
}

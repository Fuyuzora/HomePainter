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
    
    // IBActions:
    @IBAction private func restartExperience(_ sender: UIButton){
        restartButtonHandler()
    }
    
    // Properties
    // Triggered when restart button is pressed
    var restartButtonHandler:() -> Void = {}
    
    // seconds before the timer message fades out
    private let displayDuriation: TimeInterval = 6
    
    // Timer for hiding message
    private var messageHideTimer: Timer?
    private var timers: [MessageType: Timer] = [:]
    
    // Message Handling
    func showMessage(_ text: String, autoHide: Bool = true){
        // cancel any previous hide timer
        messageHideTimer?.invalidate()
        
        messageLabel.text = text
        
        // Make sure the text is showing
        setMessageHidden(false, animated: true)
        
        if autoHide {
            messageHideTimer = Timer.scheduledTimer(withTimeInterval: displayDuriation, repeats: false, block: {[weak self] _ in
                self?.setMessageHidden(true, animated: true)
            })
        }
    }
    
    func scheduleMessage(_ text: String, inSeconds seconds: TimeInterval, messageType: MessageType){
        cancelScheduledMessage(for: messageType)
        
        let timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false, block: {[weak self] timer in
            self?.showMessage(text)
            timer.invalidate()
        })
        
        timers[messageType] = timer
    }
    
    func cancelScheduledMessage(for messageType: MessageType) {
        timers[messageType]?.invalidate()
        timers[messageType] = nil
    }
    
    func cancelAllScheduledMessage() {
        for messageType in MessageType.all{
            cancelScheduledMessage(for: messageType)
        }
    }
    
    // ARKit - get tracking state coming from a custom switchable object declared at the top of this file
    func showTrackingQualityInfo(for trackingStatus: ARCamera.TrackingState, autoHide: Bool){
        showMessage(trackingStatus.presentationString, autoHide: autoHide)
    }
    
    func escalateFeedback(for trackingState: ARCamera.TrackingState, inSeconds seconds: TimeInterval) {
        cancelScheduledMessage(for: .trackingStateEscalation)
        
        let timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false, block: {[unowned self] _ in
            self.cancelScheduledMessage(for: .trackingStateEscalation)
            var message = trackingState.presentationString
            if let recommendation = trackingState.suggestion {
                message.append(": \(recommendation)")
            }
            self.showMessage(message, autoHide: false)
        })
        timers[.trackingStateEscalation] = timer
    }
    
    private func setMessageHidden(_ hide: Bool, animated: Bool) {
        // The panel starts hidden, so show it before animating opacity
        messagePanel.isHidden = false
        guard animated else {
            messagePanel.alpha = hide ? 0 : 1
            return
        }
        UIView.animate(withDuration: 0.2, delay: 0, options: [.beginFromCurrentState], animations: {
            self.messagePanel.alpha = hide ? 0 : 1
        }, completion: nil)
    }
}

extension ARCamera.TrackingState {
    var presentationString: String {
        switch self {
        case .notAvailable:
            return "Tracking no available"
        case .normal:
            return "Tracking normal"
        case .limited(.excessiveMotion):
            return "Tracking limited\nExcessive Motion"
        case .limited(.insufficientFeatures):
            return "Tracking limited\nLimited details"
        case .limited(.initializing):
            return "Tracking limited\nInitializing"
        case .limited(.relocalizing):
            return "Tracking limited\nRecovering"
        }
    }
    
    var suggestion: String? {
        switch self {
        case .limited(.excessiveMotion):
            return "Try slowing down"
        case .limited(.insufficientFeatures):
            return "Try other surfaces"
        case .limited(.relocalizing):
            return "Try return to original position"
        default:
            return nil
        }
    }
}

//
//  VRObject.swift
//  Home Painter
//
//  Created by Robert Wan on 2019-01-23.
//  Copyright © 2019 App. All rights reserved.
//

import Foundation
import ARKit
import SceneKit

// object to be placed in an ARSCNView
class virtualObject: SCNReferenceNode {
    // model name is derived from referenceURL
    // this tells sceneKit which 3d model to load given a name
    var modelName: String {
        return referenceURL.lastPathComponent.replacingOccurrences(of: ".scn", with: "")
    }
    
    // use average objects distance to avoid rapid scale change
    private var recentVRObjectDistance = [Float]()
    
    // allowed alignments for virual objects
    // sticky notes can be placed on both hori and verti planes, painting is verti only and others are hori only
    private var allowedAlignments: [ARPlaneAnchor.Alignment] {
        if modelName == "sticky note" {
            return [.horizontal, .vertical]
        } else if modelName == "painting" {
            return [.vertical]
        } else {
            return [.horizontal]
        }
    }
    
    // current alignment for an virtual obj
    private var currentAlignment: ARPlaneAnchor.Alignment = .horizontal
    
    // whether the obj is currently changing alignment (????
    private var changingAlignment: Bool = false
    
    
    
// not sure why would we need this
// ===================================================================================================================
    // remember last rotation when aligned horizontally
    var rotationWhenAlignedHorizontally: Float = 0.0
    
    // for currect rotation, rotate wrt local y not world y
    // rotate first child node not self
    var objRotation: Float {
        get {
            return childNodes.first!.eulerAngles.y
        }
        set(newValue) {
            var normalized = newValue.truncatingRemainder(dividingBy: 2 * .pi)
            normalized = (normalized + 2 * .pi).truncatingRemainder(dividingBy: 2 * .pi)
            if (normalized > .pi) {
                normalized -= 2 * .pi
            }
            childNodes.first!.eulerAngles.y = normalized
            if (currentAlignment == .horizontal) {
                rotationWhenAlignedHorizontally = normalized
            }
        }
    }
// ===================================================================================================================
    
    // obj's anchor
    var anchor: ARAnchor?
    
    // reset the position of the object
    func reset() {
        recentVRObjectDistance.removeAll()
    }
    
    // helper method determining available placement options
    
    // QUESTION: why return true when planeAnchor doesnt have a value?
    func isPlacementValid(on planeAnchor: ARPlaneAnchor?) -> Bool{
        if let anchor = planeAnchor {
            return allowedAlignments.contains(anchor.alignment)
        }
        return true
    }
    
    // set the position of the obj based on the position
    
    func setTransform(_ newTransform: float4x4,
                      relativeTo cameraTransform: float4x4,
                      smoothMovement: Bool,
                      alignment: ARPlaneAnchor.Alignment,
                      allowAnimation: Bool) {
        let cameraWorldPosition = cameraTransform.translation
        var positionOffsetFromCamera = newTransform.translation - cameraWorldPosition
        
        // limit the maximum distance away from camera is 10m
        if (simd_length(positionOffsetFromCamera) > 10) {
            positionOffsetFromCamera = simd_normalize(positionOffsetFromCamera)
            positionOffsetFromCamera *= 10
        }
    }
}

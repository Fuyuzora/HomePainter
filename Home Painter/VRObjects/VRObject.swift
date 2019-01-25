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
    private var isChangingAlignment: Bool = false
    
    
    
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
        
        // smoothmovement: compute the average distance between the camera and the object for the last 10 update
        // The distance is calculated from the camera to the object. Averaging the distance does _not_ make the object lag
        if smoothMovement {
            let hitResultDistance = simd_length(positionOffsetFromCamera)
            // add the lastest position and keep 10 distances to smooth the movement
            recentVRObjectDistance.append(hitResultDistance)
            recentVRObjectDistance = Array(recentVRObjectDistance.suffix(10))
            let averageDistance = recentVRObjectDistance.average!
            let averageDistancePosition = simd_normalize(positionOffsetFromCamera) * averageDistance
            simdPosition = positionOffsetFromCamera + averageDistancePosition
        } else {
            simdPosition = cameraWorldPosition + positionOffsetFromCamera
        }
        
        updateAlignment(to: alignment, transform: newTransform, allowAnimation: allowAnimation)
    }
    
    // setting object's alignment
    func updateAlignment(to newAlignment: ARPlaneAnchor.Alignment, transform: float4x4, allowAnimation: Bool){
        if isChangingAlignment {
            return
        }
        // only animate if alignment is changed
        let animationDuration = (newAlignment != currentAlignment && allowAnimation) ? 0.5 : 0
        var newObjectRotation: Float?
        switch (currentAlignment, newAlignment){
        // doesnt need to be changed, unlike vertical
        case (.horizontal, .horizontal):
            return
        // when changing to horizontal rotation, restore to previous horizontal rotation
        case (.horizontal, .vertical):
            newObjectRotation = rotationWhenAlignedHorizontally
        //when changing to vertical rotation, reset the object's rotation (y-up)
        case (.vertical, .horizontal):
            newObjectRotation = 0.0001
        default:
            break
        }
        currentAlignment = newAlignment
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = animationDuration
        SCNTransaction.completionBlock = {
            self.isChangingAlignment = false
        }
        isChangingAlignment = true
        
        // use filtered position rather than exact position
        var multableTransform = transform
        multableTransform.translation = simdWorldPosition
        simdTransform = multableTransform
        
        if newObjectRotation != nil {
            newObjectRotation = newObjectRotation!
        }
        
        SCNTransaction.commit()
    }
    
    // adjust on to plane anchor
    func adjustOnToPlaneAnchor(_ anchor:ARPlaneAnchor, using node: SCNNode){
        // test if the alignment of the plane is compatible with the object's allowed placement
        if !allowedAlignments.contains(anchor.alignment){
            return
        }
        // get the object's position in the plane's coord system
        // position is self.position, a member of SCNReferenceNode, inherited from SCNNode
        let planePosition = node.convertPosition(position, to: parent)
        
        // check if obj is already in the plane
        guard planePosition.y != 0 else {return}
        
        // add 10% tolerance at the corner of the plane
        let tolerance:Float = 0.1
        
        let minX = anchor.center.x - anchor.extent.x / 2 - anchor.extent.x * tolerance
        let maxX = anchor.center.x + anchor.extent.x / 2 + anchor.extent.x * tolerance
        let minZ = anchor.center.z - anchor.extent.z / 2 - anchor.extent.z * tolerance
        let maxZ = anchor.center.z + anchor.extent.z / 2 + anchor.extent.z * tolerance
        
        // return if x and z are not in range
        guard (minX...maxX).contains(planePosition.x) && (minZ...maxZ).contains(planePosition.z) else {
            return
        }
        
        // move on to the plane if it is close, but dont update if it is too close
        let verticalAllowance: Float = 0.05
        let epsilon: Float = 0.001
        let distanceToPlane = abs(planePosition.y)
        if distanceToPlane > epsilon && distanceToPlane < verticalAllowance {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = CFTimeInterval(distanceToPlane * 500) // 2mm/s
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name:CAMediaTimingFunctionName.easeInEaseOut)
            position.y = anchor.transform.columns.3.y
            updateAlignment(to: anchor.alignment, transform: simdWorldTransform, allowAnimation: false)
            SCNTransaction.commit()
        }
    }
}

// static properties and methods
extension virtualObject {
    // Load all models from models.scnassets
    static let availableObjects: [virtualObject] = {
        let modelsURL = Bundle.main.url(forResource: "Model.scnassets", withExtension: nil)!
        let fileEnumerator = FileManager().enumerator(at: modelsURL, includingPropertiesForKeys: [])!
        
        return fileEnumerator.compactMap {element in
            let url = element as! URL
            guard url.pathExtension == "scn" && !url.path.contains("lightning") else {return nil}
            return virtualObject(url: url)
        }
    }()
    
    // Returns a virtualObject if one exists as an ansestor of the provided node
    static func existingObjectContainingNode(_ node:SCNNode) -> virtualObject? {
        if let virtualObjRoot = node as? virtualObject {
            return virtualObjRoot
        }
        
        guard let parent = node.parent else {return nil}
        
        return existingObjectContainingNode(parent)
    }
}

extension Collection where Element == Float, Index == Int {
    // return the mean of a array of float numbers
    var average: Float? {
        guard !isEmpty else {
            return nil
        }
        let sum = reduce(Float(0)) {
            current, next -> Float in
            return current + next
        }
        return sum/Float(count)
    }
}

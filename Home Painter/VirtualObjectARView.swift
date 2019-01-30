//
//  VirtualObjectARView.swift
//  Home Painter
//
//  Created by Robert Wan on 2019-01-23.
//  Copyright © 2019 App. All rights reserved.
//

import Foundation
import UIKit
import ARKit
import SceneKit

class VirtualObjectView: ARSCNView {
    // Position testing
    // Hit test against sceneView to find the project at the provided point
    
    var lightingRootNode: SCNNode? {
        return scene.rootNode.childNode(withName: "lightngRootNode", recursively: true)
    }
    
    func virObject(at point: CGPoint) -> virtualObject? {
        let hitTestOptions: [SCNHitTestOption: Any] = [.boundingBoxOnly: true]
        let hitTestResults = hitTest(point, options: hitTestOptions)
        
        return hitTestResults.lazy.compactMap{ result in
            return virtualObject.existingObjectContainingNode(result.node)
        }.first
    }
    
    func smartHitTest(_ point: CGPoint,
                      infinitePlane: Bool = false,
                      objectPosition: float3? = nil,
                      allowAlignments: [ARPlaneAnchor.Alignment] = [.horizontal, .vertical]) ->  ARHitTestResult? {
        // Perform hit test
        let result = hitTest(point, types: [.existingPlaneUsingGeometry, .estimatedVerticalPlane, .estimatedHorizontalPlane])
        
        // 1. Check for result on an existing plane using geometry
        if let existingPlaneUsingGeometryResult = result.first(where: { $0.type == .existingPlaneUsingGeometry}),
            let planeAnchor = existingPlaneUsingGeometryResult.anchor as? ARPlaneAnchor, allowAlignments.contains(planeAnchor.alignment) {
            return existingPlaneUsingGeometryResult
        }
        
        // 2. Check for result on an existing plane, assuming dimension is infinite
        //    Loop though all hits against infinite exising plane
        //    Return the nearest vertical plane or nearest within 5cm of the object
        if infinitePlane {
            let infinitePlaneResults = hitTest(point, types: .existingPlane)
            
            for infinitePlaneResult in infinitePlaneResults {
                if let planeAnchor = infinitePlaneResult.anchor as? ARPlaneAnchor, allowAlignments.contains(planeAnchor.alignment){
                    if planeAnchor.alignment == .vertical {
                        // Return the first vertical hit test result
                        return infinitePlaneResult
                    } else {
                        // For horizontal planes only the one close to the object is wanted
                        if let objectY = objectPosition?.y {
                            let planeY = infinitePlaneResult.worldTransform.translation.y
                            if objectY > planeY - 0.05 && objectY < planeY + 0.05 {
                                return infinitePlaneResult
                            }
                        } else {
                            return infinitePlaneResult
                        }
                    }
                }
            }
        }
        
        // 3. Finally, check for a result on estimated planes
        let vResult = result.first(where: { $0.type == .estimatedVerticalPlane })
        let hResult = result.first(where: { $0.type == .estimatedHorizontalPlane })
        switch (allowAlignments.contains(.horizontal), allowAlignments.contains(.vertical)) {
        case (true, false):
            return hResult
        case (false, true):
            // Allow feedback for horizontal as well cuz objects can be placed on hori plane as well
            return vResult ?? hResult
        case (true, true):
            if hResult != nil && vResult != nil {
                return hResult!.distance < vResult!.distance ? hResult! : vResult!
            } else {
                return hResult ?? vResult
            }
        default:
            return nil
        }
    }
    
    // Object anchor
    func addOrUpdateAnchor(for object: virtualObject) {
        // if the anchor is not nil, remove it from the session
        // (if there is an object already, and tap on it -> it get removed!)
        if let anchor = object.anchor {
            session.remove(anchor: anchor)
        }
        
        // create a new anchor with the object's current transform and add to the session
        let newAnchor = ARAnchor(transform: object.simdWorldTransform)
        object.anchor = newAnchor
        session.add(anchor: object.anchor!)
    }
    
    func setupDirectionalLighting(queue: DispatchQueue) {
        guard self.lightingRootNode == nil else {
            return
        }
        
        // Add directional lighting for dynamic highlights in environmental-based lighting
        guard let lightingScene = SCNScene(named: "lighting.scn", inDirectory: "Models.scnassets", options: nil) else {
            print("Error setting up directional lighting - why dont you just remove this function?")
            return
        }
        let lightingRootNode = SCNNode()
        lightingRootNode.name = "lightingRootNode"
        
        for node in lightingScene.rootNode.childNodes where node.light != nil {
            lightingRootNode.addChildNode(node)
        }
        
        queue.async {
            self.scene.rootNode.addChildNode(lightingRootNode)
        }
    }
    
    // Assign new intensity to old nodes
    func updateDirectionalLighting(intensity: CGFloat, queue: DispatchQueue) {
        guard let lightingRootNode = self.lightingRootNode else {
            return
        }
        queue.async {
            for node in lightingRootNode.childNodes {
                node.light?.intensity = intensity
            }
        }
    }
}

extension SCNView {
    // Type conversion wrapper for original unProjectPoint(_:) method
    // Used in context where sticking to simd float3 in helpful
    func unProjectPoint(_ point: float3) -> float3 {
        return float3(unprojectPoint(SCNVector3(point)))
    }
}

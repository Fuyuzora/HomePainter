//
//  VirtualObjectLoader.swift
//  Home Painter
//
//  Created by Robert Wan on 2019-01-25.
//  Copyright © 2019 App. All rights reserved.
//

import Foundation
import ARKit

// Load multiple virtualObjects in a background queue to display them when needed
class VirtualObjectLoader {
    private(set) var loadedObjects = [virtualObject]()
    private(set) var isLoading = false
    
    // Loading objects
    // Load a virtualObject in backgound queue.
    // A load handler is invoked once a object is loaded in the background
    func loadVirtualObject(_ object:virtualObject, loadedHandler: @escaping (virtualObject) -> Void){
        isLoading = true
        loadedObjects.append(object)
        
        // Load content asynchronously
        DispatchQueue.global(qos: .background).async {
            object.reset()
            object.load()
            
            self.isLoading = false
            loadedHandler(object)
        }
    }
    
    // Remove all virtual objects
    func removeAllVirtualObject() {
        for index in loadedObjects.indices.reversed() {
            removeVirtualObject(at: index)
        }
    }
    
    func removeVirtualObject(at index: Int){
        guard loadedObjects.indices.contains(index) else {return}
        loadedObjects[index].removeFromParentNode()
        loadedObjects.remove(at: index)
    }
}

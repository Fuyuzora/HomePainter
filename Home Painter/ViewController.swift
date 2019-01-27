//
//  ViewController.swift
//  Home Painter
//
//  Created by Robert Wan on 2019-01-18.
//  Copyright © 2019 App. All rights reserved.
//

import UIKit
import ARKit
import SceneKit

class ViewController: UIViewController{
    
    @IBOutlet weak var sceneView: VirtualObjectView!
    @IBOutlet weak var addObjectButton: UIButton!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    var focusSquare = FocusSquare()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

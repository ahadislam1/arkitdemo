//
//  ViewController.swift
//  arkitdemo
//
//  Created by Ahad Islam on 1/4/20.
//  Copyright © 2020 Ahad Islam. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet weak var arSceneView: ARSCNView!
    let config = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        arSceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        arSceneView.session.run(config)
    }


}

extension ViewController: ARSCNViewDelegate {
    
}

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
    var nodeWeCanChange: SCNNode?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        config.planeDetection = .vertical
        arSceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        arSceneView.session.run(config)
        let capsuleNode = SCNNode(geometry: SCNCapsule(capRadius: 0.03, height: 0.1))
        capsuleNode.position = SCNVector3(0.1, 0.1, -0.1)
        arSceneView.scene.rootNode.addChildNode(capsuleNode)
    }
    
    
}

extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        if nodeWeCanChange == nil {
        //1. Check We Have Detected An ARPlaneAnchor
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        //2. Get The Size Of The ARPlaneAnchor
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        
        //3. Create An SCNPlane Which Matches The Size Of The ARPlaneAnchor
        let nodeWeCanChange = SCNNode(geometry: SCNPlane(width: width, height: height))
        
        //4. Rotate It
        nodeWeCanChange.eulerAngles.x = -.pi/2
        
        //5. Set It's Colour To Red
        nodeWeCanChange.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        
        //4. Add It To Our Node & Thus The Hiearchy
        node.addChildNode(nodeWeCanChange)
        }
    }
}

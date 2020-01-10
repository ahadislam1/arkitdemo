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
import RealityKit
import MultipeerConnectivity

class ViewController: UIViewController {
    
    @IBOutlet weak var arSceneView: ARSCNView!
    let config = ARWorldTrackingConfiguration()
    var nodeWeCanChange: SCNNode?
    var multipeerSession: MultipeerSession?
    var peerSessionIDs = [MCPeerID: String]()
    var sessionIDObservation: NSKeyValueObservation?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        sessionIDObservation = observe(\.arSceneView.session.identifier, options: [.new]) { object, change in
            print("SessionID changed to: \(change.newValue!)")
            // Tell all other peers about your ARSession's changed ID, so
            // that they can keep track of which ARAnchors are yours.
            guard let multipeerSession = self.multipeerSession else { return }
            self.sendARSessionIDTo(peers: multipeerSession.connectedPeers)
        }
        UIApplication.shared.isIdleTimerDisabled = true
        arSceneView.session.delegate = self
        config.planeDetection = .vertical
        print(config.isCollaborationEnabled)
        config.isCollaborationEnabled = true
        arSceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        arSceneView.session.run(config)
        let capsuleNode = SCNNode(geometry: SCNCapsule(capRadius: 0.03, height: 0.1))
        capsuleNode.position = SCNVector3(0.1, 0.1, -0.1)
        arSceneView.scene.rootNode.addChildNode(capsuleNode)
        multipeerSession = MultipeerSession(receivedDataHandler: receivedData, peerJoinedHandler:
        peerJoined, peerLeftHandler: peerLeft, peerDiscoveredHandler: peerDiscovered)
    }
    
    
}

extension ViewController: ARSCNViewDelegate, ARSessionDelegate {
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
            nodeWeCanChange.geometry?.firstMaterial?.diffuse.contents = UIImage(systemName: "rosette")
            
            //4. Add It To Our Node & Thus The Hiearchy
            node.addChildNode(nodeWeCanChange)
        }
        
    }
    
    func session(_ session: ARSession, didOutputCollaborationData data: ARSession.CollaborationData) {
        guard let multipeerSession = multipeerSession else { return }
        print("Outputting Collaboration Data...")
        if !multipeerSession.connectedPeers.isEmpty {
            guard let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: data, requiringSecureCoding: true)
                else { fatalError("Unexpectedly failed to encode collaboration data.") }
            // Use reliable mode if the data is critical, and unreliable mode if the data is optional.
            let dataIsCritical = data.priority == .critical
            multipeerSession.sendToAllPeers(encodedData, reliably: dataIsCritical)
        } else {
            print("Deferred sending collaboration to later because there are no peers.")
        }
    }
    
    func receivedData(_ data: Data, from peer: MCPeerID) {
        if let collaborationData = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARSession.CollaborationData.self, from: data) {
            print("Updated session.")
            arSceneView.session.update(with: collaborationData)
            return
        }
        // ...
        let sessionIDCommandString = "SessionID:"
        if let commandString = String(data: data, encoding: .utf8), commandString.starts(with: sessionIDCommandString) {
            let newSessionID = String(commandString[commandString.index(commandString.startIndex,
                                                                     offsetBy: sessionIDCommandString.count)...])
            // If this peer was using a different session ID before, remove all its associated anchors.
            // This will remove the old participant anchor and its geometry from the scene.
            
            peerSessionIDs[peer] = newSessionID
        }
    }
    
    /// - Tag: PeerJoined
    func peerJoined(_ peer: MCPeerID) {
        sendARSessionIDTo(peers: [peer])
    }
        
    func peerLeft(_ peer: MCPeerID) {
        // Remove all ARAnchors associated with the peer that just left the experience.
        if let sessionID = peerSessionIDs[peer] {
            peerSessionIDs.removeValue(forKey: peer)
        }
    }
    
    private func sendARSessionIDTo(peers: [MCPeerID]) {
        guard let multipeerSession = multipeerSession else { return }
        print("Sending ARSessionID to peers...")
        let idString = arSceneView.session.identifier.uuidString
        let command = "SessionID:" + idString
        if let commandData = command.data(using: .utf8) {
            multipeerSession.sendToPeers(commandData, reliably: true, peers: peers)
        }
    }
    
    func peerDiscovered(_ peer: MCPeerID) -> Bool {
        guard let multipeerSession = multipeerSession else { return false }
        
        if multipeerSession.connectedPeers.count > 4 {
            return false
        } else {
            return true
        }
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let anchor = anchor as? ARParticipantAnchor {
                print("ARPArticipantAnchor located.")
                 
            }
        }
    }
    
}

//
//  ViewController.swift
//  voxelMap
//
//  Created by Ferdinand Lösch on 21/10/2019.
//  Copyright © 2019 Ferdinand Lösch. All rights reserved.
//

import ARKit
import SceneKit
import UIKit

class ViewController: UIViewController, ARSCNViewDelegate {
    @IBOutlet var sceneView: ARSCNView!
    var sphereNode: SCNNode!

    override func viewDidLoad() {
        super.viewDidLoad()

        //y
        sceneView.delegate = self
        sceneView.isPlaying = true

        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true

        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!

        // Set the scene to the view
        sceneView.scene = scene
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate

    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_: SCNSceneRenderer, nodeFor _: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        return node
    }

    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        print("a")
//        guard let currentFrame = self.sceneView.session.currentFrame,
//            let featurePointsArray = currentFrame.rawFeaturePoints?.points else { return }
//        visualizeFeaturePointsIn(featurePointsArray)
    }
    
    func renderer(aRenderer:SCNSceneRenderer, updateAtTime time:TimeInterval) {
        print("b")
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        print("X")
        
    }
    
    func visualizeFeaturePointsIn(_ featurePointsArray: [vector_float3]){
           
           //1. Remove Any Existing Nodes
           self.sceneView.scene.rootNode.enumerateChildNodes { (featurePoint, _) in
               featurePoint.geometry = nil
               featurePoint.removeFromParentNode()
           }
           
           //3. Loop Through The Feature Points & Add Them To The Hierachy
           featurePointsArray.forEach { (pointLocation) in
               
               //Clone The SphereNode To Reduce CPU
               let clone = sphereNode.clone()
               clone.position = SCNVector3(pointLocation.x, pointLocation.y, pointLocation.z)
               self.sceneView.scene.rootNode.addChildNode(clone)
           }

    }
    
    /// Generates A Spherical SCNNode
    func generateNode(){
        let sphereNode = SCNNode()
        let sphereGeometry = SCNSphere(radius: 0.001)
        sphereGeometry.firstMaterial?.diffuse.contents = UIColor.cyan
        sphereNode.geometry = sphereGeometry
    }

    

    func session(_: ARSession, didFailWithError _: Error) {
        // Present an error message to the user
    }

    func sessionWasInterrupted(_: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }

    func sessionInterruptionEnded(_: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }
}

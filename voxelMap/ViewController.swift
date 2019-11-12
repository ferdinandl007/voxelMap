//
//  ViewController.swift
//  voxelMap
//
//  Created by Ferdinand Lösch on 21/10/2019.
//  Copyright © 2019 Ferdinand Lösch. All rights reserved.
//

import ARKit
import UIKit

class ViewController: UIViewController {
    @IBOutlet var augmentedRealityView: ARSCNView!

    let configuration = ARWorldTrackingConfiguration()

    let augmentedRealitySession = ARSession()

    let voxelMap = VoxelMap(VoxelGridCellSize: 0.1)

    @IBOutlet var debugimage: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupARSession()
    }

    override var prefersStatusBarHidden: Bool { return true }

    override func didReceiveMemoryWarning() { super.didReceiveMemoryWarning() }

    /// Sets Up The ARSession
    func setupARSession() {
        if #available(iOS 11.3, *) {
            configuration.planeDetection = [.horizontal, .vertical]
        } else {
            configuration.planeDetection = [.horizontal]
        }

        augmentedRealityView.session = augmentedRealitySession
        augmentedRealityView.delegate = self

        augmentedRealitySession.run(configuration)
    }

    @IBAction func makeVoxels(_: Any) {
        voxelMap.getVoxelMap().forEach { self.augmentedRealityView.scene.rootNode.addChildNode($0) }
        let view = voxelMap.getObstacleGraphDebug()
        debugimage.addSubview(view)

        print(voxelMap.makeGraph())
    }

    @IBAction func goToMap(_: Any) {
        voxelMap.getVoxelMap().forEach { self.augmentedRealityView.scene.rootNode.addChildNode($0) }
        augmentedRealityView.scene.rootNode.enumerateChildNodes { node, _ in
            if node.name == "Plane" {
                node.removeFromParentNode()
            }
        }

        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        if let viewController = mainStoryboard.instantiateViewController(withIdentifier: "Map") as? MapViewController {
            viewController.node = augmentedRealityView.scene.rootNode.clone()
            present(viewController, animated: true, completion: nil)
        }
    }
}

extension ViewController: ARSCNViewDelegate {
    func renderer(_: SCNSceneRenderer, updateAtTime _: TimeInterval) {
        // 1. Check Our Frame Is Valid & That We Have Received Our Raw Feature Points
        guard let currentFrame = self.augmentedRealitySession.currentFrame,
            let featurePointsArray = currentFrame.rawFeaturePoints?.points else { return }
        voxelMap.addVoxels(featurePointsArray)
    }

    func renderer(_: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Place content only for anchors found by plane detection.
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }

        // Create a custom object to visualize the plane geometry and extent.
        let plane = Plane(anchor: planeAnchor, in: augmentedRealityView)
        plane.name = "Plane"

        // Add the visualization to the ARKit-managed node so that it tracks
        // changes in the plane anchor as plane estimation continues.
        node.addChildNode(plane)
        voxelMap.updateGroundPlane(planeAnchor)
    }

    /// - Tag: UpdateARContent
    func renderer(_: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // Update only anchors and nodes set up by `renderer(_:didAdd:for:)`.
        guard let planeAnchor = anchor as? ARPlaneAnchor,
            let plane = node.childNodes.first as? Plane
        else { return }
        voxelMap.updateGroundPlane(planeAnchor)
        // Update ARSCNPlaneGeometry to the anchor's new estimated shape.
        if let planeGeometry = plane.meshNode.geometry as? ARSCNPlaneGeometry {
            planeGeometry.update(from: planeAnchor.geometry)
        }
        // Update extent visualization to the anchor's new bounding rectangle.
        if let extentGeometry = plane.extentNode.geometry as? SCNPlane {
            extentGeometry.width = CGFloat(planeAnchor.extent.x)
            extentGeometry.height = CGFloat(planeAnchor.extent.z)
            plane.extentNode.simdPosition = planeAnchor.center
        }
    }
}

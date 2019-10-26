//
//  ViewController.swift
//  voxelMap
//
//  Created by Ferdinand Lösch on 21/10/2019.
//  Copyright © 2019 Ferdinand Lösch. All rights reserved.
//

import ARKit
import UIKit

extension ViewController: ARSCNViewDelegate {
    func renderer(_: SCNSceneRenderer, updateAtTime _: TimeInterval) {
        // 1. Check Our Frame Is Valid & That We Have Received Our Raw Feature Points
        guard let currentFrame = self.augmentedRealitySession.currentFrame,
            let featurePointsArray = currentFrame.rawFeaturePoints?.points else { return }

        addVoxels(featurePointsArray)
    }

    func addVoxels(_ featurePointsArray: [vector_float3]) {
        // Loop Through The Feature Points & Add Them To The Voxel map.
        featurePointsArray.forEach { voxelMap.addVoxel(vector: $0) }
    }
}

class ViewController: UIViewController {
    @IBOutlet var augmentedRealityView: ARSCNView!

    let configuration = ARWorldTrackingConfiguration()

    let augmentedRealitySession = ARSession()

    let voxelMap = VoxelMap()

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
        augmentedRealityView.scene.rootNode.enumerateChildNodes { featurePoint, _ in
            featurePoint.geometry = nil
            featurePoint.removeFromParentNode()
        }
        voxelMap.getVoxelMap().forEach { augmentedRealityView.scene.rootNode.addChildNode($0) }
    }

    @IBAction func goToMap(_: Any) {
        voxelMap.getVoxelMap().forEach { augmentedRealityView.scene.rootNode.addChildNode($0) }
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        if let viewController = mainStoryboard.instantiateViewController(withIdentifier: "Map") as? MapViewController {
            viewController.node = augmentedRealityView.scene.rootNode.clone()
            present(viewController, animated: true, completion: nil)
        }
    }
}

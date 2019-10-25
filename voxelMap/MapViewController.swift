//
//  MapViewController.swift
//  voxelMap
//
//  Created by Ferdinand Lösch on 23/10/2019.
//  Copyright © 2019 Ferdinand Lösch. All rights reserved.
//

import GameplayKit
import SpriteKit
import UIKit

class MapViewController: UIViewController {
    let scene = SCNScene()
    var node: SCNNode?

    override func viewDidLoad() {
        super.viewDidLoad()

        let scnView = view as! SCNView

        scnView.scene = scene

        scnView.allowsCameraControl = true

        scnView.autoenablesDefaultLighting = true

        scnView.showsStatistics = true

        scnView.backgroundColor = UIColor.black

        guard let node = self.node else { return }

        print("Add node to scene.")

        scene.rootNode.addChildNode(node)
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    @IBAction func BackButton(_: Any) {
        dismiss(animated: true, completion: nil)
    }
}

//
//  ViewController.swift
//  voxelMap
//
//  Created by Ferdinand Lösch on 21/10/2019.
//  Copyright © 2019 Ferdinand Lösch. All rights reserved.
//

import ARKit
import ARNavigationKit
import UIKit

class ViewController: UIViewController {
    @IBOutlet var augmentedRealityView: ARSCNView!

    let configuration = ARWorldTrackingConfiguration()

    let augmentedRealitySession = ARSession()

    let voxelMap = ARNavigationKit(VoxelGridCellSize: 0.1)

    var end = SCNVector3()

    var sliderValue = 0

    var voxleRootNode = SCNNode()

    var timer = Timer()

    @IBOutlet var sliderLabel: UILabel!
    @IBOutlet var debugimage: UIView!
    @IBOutlet var spinner: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapRecognizer.numberOfTapsRequired = 2
        view.addGestureRecognizer(tapRecognizer)
        setupARSession()
        voxelMap.arNavigationKitDelegate = self
        voxelMap.filter = .removeSingle
        spinner.isHidden = true
    }

    @objc func handleTap(sender: UITapGestureRecognizer) {
        let tapLocation = sender.location(in: augmentedRealityView)

        let hitTestResults = augmentedRealityView.hitTest(tapLocation, types: .featurePoint)

        for result in hitTestResults {
            let pos = result.worldTransform.columns.3
            addMarker(SCNVector3(pos.x, pos.y + 0.06, pos.z))
        }
    }

    @IBAction func setValue(_: Any) {
        spinner.isHidden = false
        spinner.startAnimating()
        voxelMap.noiseLevel = sliderValue
        let transform = augmentedRealityView.pointOfView!.transform
        let cam = SCNVector3(transform.m41, transform.m42, transform.m43)
        voxelMap.getObstacleGraphAndPathDebug(start: cam, end: end)
    }

    @IBAction func slider(_ sender: UISlider) {
        sliderValue = Int(sender.value)
        sliderLabel.text = "\(sliderValue)"
    }

    func addMarker(_ p: SCNVector3) {
        let pin = newPinMarker()!
        pin.worldPosition = p
        pin.scale = SCNVector3(x: 1, y: 1, z: 1) * 3.25
        let transform = augmentedRealityView.pointOfView!.transform
        let cam = SCNVector3(transform.m41, transform.m42, transform.m43)
        end = p
        augmentedRealityView.scene.rootNode.addChildNode(pin)
        voxelMap.getObstacleGraphAndPathDebug(start: cam, end: p)
        spinner.isHidden = false
        spinner.startAnimating()
    }

    func newPinMarker(color: UIColor = UIColor.magenta,
                      addLights _: Bool = true,
                      constantLighting: Bool = false) -> SCNNode? {
        guard let pinRoot = SCNScene(named: "pin.scn")?.rootNode else { return nil }

        guard let pin = pinRoot.childNode(withName: "pin", recursively: true) else { return nil }

        if let cyl = pin.childNode(withName: "cylinder", recursively: true) {
            cyl.renderingOrder = 5601
            if constantLighting {
                cyl.geometry?.firstMaterial?.lightingModel = .constant
            }
        }

        if let cyl = pin.childNode(withName: "cone", recursively: true) {
            cyl.renderingOrder = 5600
            if constantLighting {
                cyl.geometry?.firstMaterial?.lightingModel = .constant
            }
        }

        if let cyl = pin.childNode(withName: "sphere", recursively: true) {
            cyl.geometry?.firstMaterial?.diffuse.contents = color
            cyl.renderingOrder = 5602
            if constantLighting {
                cyl.geometry?.firstMaterial?.lightingModel = .constant
            }
        }

        return pin
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

        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            guard let currentFrame = self.augmentedRealitySession.currentFrame,
                let featurePointsArray = currentFrame.rawFeaturePoints?.points else { return }
            self.voxelMap.addVoxels(featurePointsArray)
        }
    }

    @IBAction func makePath(_: Any) {
        let transform = augmentedRealityView.pointOfView!.transform
        let cam = SCNVector3(transform.m41, transform.m42, transform.m43)
        voxelMap.getPath(start: cam, end: end)
        spinner.isHidden = false
        spinner.startAnimating()
    }

    @IBAction func makeVoxels(_: Any) {
//        voxelMap.getVoxelMap().forEach { self.augmentedRealityView.scene.rootNode.addChildNode($0) }
//        voxelMap.getVoxelMap(redrawAll: true) { v in
//
//        }
        let transform = augmentedRealityView.pointOfView!.transform
        let cam = SCNVector3(transform.m41, transform.m42, transform.m43)
        voxelMap.getObstacleGraphAndPathDebug(start: cam, end: end)
        spinner.isHidden = false
        spinner.startAnimating()
    }

    @IBAction func goToMap(_: Any) {
        voxelMap.getVoxelMap(redrawAll: true, onlyObstacles: true) { v in
            v.forEach { self.voxleRootNode.addChildNode($0) }
            DispatchQueue.main.async {
                let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                if let viewController = mainStoryboard.instantiateViewController(withIdentifier: "Map") as? MapViewController {
                    viewController.node = self.voxleRootNode.clone()
                    self.present(viewController, animated: true, completion: nil)
                }
            }
        }
    }
}

extension ViewController: ARSCNViewDelegate {
    func renderer(_: SCNSceneRenderer, updateAtTime _: TimeInterval) {
        // 1. Check Our Frame Is Valid & That We Have Received Our Raw Feature Points
//        guard let currentFrame = self.augmentedRealitySession.currentFrame,
//            let featurePointsArray = currentFrame.rawFeaturePoints?.points else { return }
//        voxelMap.addVoxels(featurePointsArray)
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

extension ViewController: ARNavigationKitDelegate {
    func getPathupdate(_ path: [vector_float3]?) {
        augmentedRealityView.scene.rootNode.enumerateChildNodes { node, _ in
            if node.name == "path" {
                node.removeFromParentNode()
            }
        }
        let box = SCNBox(width: CGFloat(0.05), height: CGFloat(0.05), length: CGFloat(0.05), chamferRadius: 0.1)
        box.firstMaterial?.diffuse.contents = UIColor.red
        let node = SCNNode(geometry: box)
        node.name = "path"

        path?.forEach { p in
            let pathNode = node.clone()
            pathNode.position = SCNVector3(p)
            self.augmentedRealityView.scene.rootNode.addChildNode(pathNode)
        }
        spinner.isHidden = true
        spinner.stopAnimating()
    }

    func updateDebugView(_ View: UIView) {
        debugimage.addSubview(View)
        spinner.isHidden = true
        spinner.stopAnimating()
    }
}

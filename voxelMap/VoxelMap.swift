//
//  VoxelMap.swift
//  voxelMap
//
//  Created by Ferdinand Lösch on 21/10/2019.
//  Copyright © 2019 Ferdinand Lösch. All rights reserved.
//

import Foundation
import SceneKit.SCNNode
import simd

protocol VoxelMapDelegate: class {
    func update(with nodes: [SCNNode]) -> Any
}

class VoxelMap {
    weak var voxelMapDelegate: VoxelMapDelegate?
    var voxelSet = Set<Voxel>()

    func addVoxel(vector: vector_float3) {
        let voxel = Voxel(vector: vector, density: 1, level: 1)
        voxelSet.insert(voxel)
    }

    func getVoxelNodes() -> [SCNNode] {
        var nodes = [SCNNode]()
        for voxel in voxelSet {
            let box = SCNBox(width: CGFloat(voxel.level * 0.1),
                             height: CGFloat(voxel.level * 0.1),
                             length: CGFloat(voxel.level * 0.1),
                             chamferRadius: 0)
            box.firstMaterial?.diffuse.contents = UIColor.green
            let node = SCNNode(geometry: box)
            node.position = SCNVector3(voxel.vector)
            nodes.append(node)
        }
        return nodes
    }
}




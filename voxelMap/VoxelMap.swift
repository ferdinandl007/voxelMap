//
//  VoxelMap.swift
//  voxelMap
//
//  Created by Ferdinand Lösch on 21/10/2019.
//  Copyright © 2019 Ferdinand Lösch. All rights reserved.
//

import Foundation
import GameplayKit
import ModelIO
import SceneKit
import SceneKit.ModelIO
import simd

protocol VoxelMapDelegate: class {
    func update(_ nodes: [SCNNode]) -> Any
}

class VoxelMap {
    weak var voxelMapDelegate: VoxelMapDelegate?
    var voxelSet = Set<Voxel>()
    var voxelNode = Set<GKOctreeNode>()
    var octTree = GKOctree(boundingBox: GKBox(boxMin: vector_float3(-20,-20,-20), boxMax: vector_float3(20,20,20)), minimumCellSize: 0.1)
    
    func addVoxel(vector: vector_float3) {
        let voxel = Voxel(vector: vector, scale: vector_float3(10,10,10), density: 1)
        
        if voxelSet.contains(voxel) {
            guard let newVoxel = voxelSet.remove(voxel) else { return }
//            newVoxel.scale = newVoxel.scale / 10
            newVoxel.density += 1
            voxelSet.insert(newVoxel)
        } else {
             voxelSet.insert(voxel)
        }
    }
    


    func getPointCloudNode() -> SCNNode {
        let points = voxelSet.map { SIMD3<Float>($0.Position) }

        let featurePointsGeometry = pointCloudGeometry(for: points)

        let featurePointsNode = SCNNode(geometry: featurePointsGeometry)

        return featurePointsNode
    }
    
    func getVoxelMap() -> [SCNNode] {
        return voxelSet.map { (voxel) -> SCNNode in
            if voxel.density < 50 {
                return SCNNode()
            }
            print(voxel.density)
            let position = voxel.Position
            let box = SCNBox(width: CGFloat(1 / voxel.scale.x) , height: CGFloat(1 / voxel.scale.y), length:  CGFloat(1 / voxel.scale.z), chamferRadius: 0)
            box.firstMaterial?.diffuse.contents = UIColor.darkGray
            let voxelNode = SCNNode(geometry: box)
            voxelNode.position = SCNVector3(position)
            return voxelNode
        }
    }
}

extension VoxelMap {
    // Generate a geometry point cloud out of current Vertices.
    func pointCloudGeometry(for points: [SIMD3<Float>]) -> SCNGeometry? {
        guard !points.isEmpty else { return nil }

        let stride = MemoryLayout<SIMD3<Float>>.size
        let pointData = Data(bytes: points, count: stride * points.count)

        let source = SCNGeometrySource(data: pointData,
                                       semantic: SCNGeometrySource.Semantic.vertex,
                                       vectorCount: points.count,
                                       usesFloatComponents: true,
                                       componentsPerVector: 3,
                                       bytesPerComponent: MemoryLayout<Float>.size,
                                       dataOffset: 0,
                                       dataStride: stride)

        let pointSize: CGFloat = 10
        let element = SCNGeometryElement(data: nil, primitiveType: .point, primitiveCount: points.count, bytesPerIndex: 0)
        element.pointSize = 0.01
        element.minimumPointScreenSpaceRadius = pointSize * 2
        element.maximumPointScreenSpaceRadius = pointSize / 2

        let pointsGeometry = SCNGeometry(sources: [source], elements: [element])

        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        material.isDoubleSided = true
        material.locksAmbientWithDiffuse = true

        return pointsGeometry
    }
}

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

    func getVoxelNode() -> SCNNode {
        let points = voxelSet.map { SIMD3<Float>($0.vector) }

        let featurePointsGeometry = pointCloudGeometry(for: points)

        let featurePointsNode = SCNNode(geometry: featurePointsGeometry)

        return featurePointsNode
    }
}

extension VoxelMap {
    // Generate a geometry point cloud out current of Voxels.
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
        element.pointSize = 0.001
        element.minimumPointScreenSpaceRadius = pointSize
        element.maximumPointScreenSpaceRadius = pointSize

        let pointsGeometry = SCNGeometry(sources: [source], elements: [element])

        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        material.isDoubleSided = true
        material.locksAmbientWithDiffuse = true

        return pointsGeometry
    }
}

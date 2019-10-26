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

enum axes {
    case x
    case y
    case z
    case none
}

protocol VoxelMapDelegate: class {
    func update(_ nodes: [SCNNode]) -> Any
}

class VoxelMap {
    weak var voxelMapDelegate: VoxelMapDelegate?
    var voxelSet = Set<Voxel>()
    private var gridSize: Float = 50
    
    
    init(VoxelGridCellSize: Int) {
        self.gridSize = Float(VoxelGridCellSize)
    }
    
    init() { }

    // A record of voxels which have already been added to the SCNScene.
    private var alreadyRenderedVoxels = Set<Voxel>()

    func addVoxel(_ vector: vector_float3) {
        let voxel = Voxel(vector: normaliseVector(vector), scale: vector_float3(gridSize, gridSize, gridSize), density: 1)
        if voxelSet.contains(voxel) {
            guard let newVoxel = voxelSet.remove(voxel) else { return }
            newVoxel.density += 1
            voxelSet.insert(newVoxel)
        } else {
            voxelSet.insert(voxel)
        }
    }
    
    func addVoxels(_ vectors: [vector_float3]) {
        vectors.forEach { addVoxel($0)}
    }

    private func recursiveMerging(_ voxel: Voxel, axes _: axes) {
        let voxelX = voxel
        if voxelSet.contains(voxel) {
            guard let newVoxel = voxelSet.remove(voxel) else { return }
            newVoxel.density += 1
            voxelSet.insert(newVoxel)
        } else {
            return
        }

        voxelX.Position.x = voxelX.Position.x + (1 / gridSize)
        recursiveMerging(voxelX, axes: .x)
        voxelX.Position.x = voxelX.Position.x + (1 / gridSize)
        recursiveMerging(voxelX, axes: .y)
        voxelX.Position.x = voxelX.Position.x + (1 / gridSize)
        recursiveMerging(voxelX, axes: .z)
    }

    func getPointCloudNode() -> SCNNode {
        let points = voxelSet.map { SIMD3<Float>($0.Position) }

        let featurePointsGeometry = pointCloudGeometry(for: points)

        let featurePointsNode = SCNNode(geometry: featurePointsGeometry)

        return featurePointsNode
    }

    func getVoxelMap() -> [SCNNode] {
        var voxelNodes = [SCNNode]()
        for voxel in voxelSet {
            if voxel.density < 50 { continue }
            if alreadyRenderedVoxels.contains(voxel) { continue } // To increase rendering efficiency
            print(voxel.density)
            let position = voxel.Position
            let box = SCNBox(width: CGFloat(1 / voxel.scale.x), height: CGFloat(1 / voxel.scale.y), length: CGFloat(1 / voxel.scale.z), chamferRadius: 0)
            box.firstMaterial?.diffuse.contents = getRandomColoer()
            let voxelNode = SCNNode(geometry: box)
            voxelNode.position = SCNVector3(position)
            voxelNodes.append(voxelNode)
            alreadyRenderedVoxels.insert(voxel)
        }
        return voxelNodes
    }
}

extension VoxelMap {
    // Generate a geometry point cloud out of current Vertices.
    private func pointCloudGeometry(for points: [SIMD3<Float>]) -> SCNGeometry? {
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
        material.diffuse.contents = getRandomColoer()
        material.isDoubleSided = true
        material.locksAmbientWithDiffuse = true

        return pointsGeometry
    }

    private func normaliseVector(_ vector: vector_float3) -> vector_float3 {
        return vector_float3(vector_int3(vector * gridSize)) / gridSize
    }

    private func getRandomColoer() -> UIColor {
        switch Int.random(in: 0 ... 2) {
        case 0:
            return UIColor.gray
        case 1:
            return UIColor.darkGray
        case 2:
            return UIColor.lightGray
        default:
            return UIColor.orange
        }
    }
}

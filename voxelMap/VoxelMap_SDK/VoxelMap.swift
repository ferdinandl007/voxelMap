//
//  VoxelMap.swift
//  voxelMap
//
//  Created by Ferdinand Lösch on 21/10/2019.
//  Copyright © 2019 Ferdinand Lösch. All rights reserved.
//

import ARKit
import Foundation
import GameplayKit
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
    let queue = DispatchQueue(label: "Voxel")
    weak var voxelMapDelegate: VoxelMapDelegate?
    var voxelSet = Set<Voxel>()
    private var gridSize: Float!
    private var groundHeight: Float?
    private var xMax: Float? // Max width
    private var xMin: Float? // Min width
    private var zMax: Float? // Max length
    private var zMin: Float? // Min length

    ///  Sets the minimum resolution of a Voxel in metres cubed as well as the grid size used.
    /// - Parameter VoxelGridCellSize: grid cell size  in metres.
    init(VoxelGridCellSize: Float) {
        gridSize = 1 / VoxelGridCellSize
    }

    init() {
        gridSize = 50
    }

    /// A record of voxels which have already been added to the SCNScene.
    private var alreadyRenderedVoxels = Set<Voxel>()

    func addVoxel(_ vector: vector_float3) {
        let voxel = Voxel(vector: normaliseVector(vector), scale: vector_float3(gridSize, gridSize, gridSize), density: 1)
        if voxelSet.contains(voxel) {
            guard let newVoxel = self.voxelSet.remove(voxel) else { return }
            newVoxel.density += 1
            voxelSet.insert(newVoxel)
        } else {
            voxelSet.insert(voxel)
        }
    }

    func addVoxels(_ vectors: [vector_float3]) {
        vectors.forEach { addVoxel($0) }
    }

    func updateGroundPlane(_ plane: ARPlaneAnchor) {
        groundHeight = min(plane.transform.columns.3.y, groundHeight ?? Float(Int.max))
    }

    func getPointCloudNode() -> SCNNode {
        let voxels = voxelSet
        let points = voxels.map { SIMD3<Float>($0.Position) }

        let featurePointsGeometry = pointCloudGeometry(for: points)

        let featurePointsNode = SCNNode(geometry: featurePointsGeometry)

        return featurePointsNode
    }

    func getPath(start: vector_float3, end _: vector_float3) -> [vector_float3]? {
        setMinMax()
        guard let matrix = makeGraph() else { return nil }
        guard let xmax = xMax else { return nil }
        guard let zmax = zMax else { return nil }
        let _start = Position(Int((xmax - start.x) / (1.0 / gridSize)),
                              Int((zmax - start.z) / (1.0 / gridSize)))
        let _end = Position(Int((xmax - start.x) / (1.0 / gridSize)),
                            Int((zmax - start.z) / (1.0 / gridSize)))
        let _path = Pathfinding.aStarPath(map: matrix, start: _start, end: _end)

        let pathVectors = _path.map { (position) -> vector_float3 in
            let xv = xmax + Float(position.x ?? 0)
            let zv = zmax + Float(position.y ?? 0)
            let x = xv * (1.0 / gridSize!)
            let z = zv * (1.0 / gridSize!)
            return vector_float3(x: x, y: (groundHeight ?? -1) + 0.4, z: z)
        }

        return pathVectors
    }

    func getVoxelMap() -> [SCNNode] {
        var voxelNodes = [SCNNode]()
        let voxels = voxelSet
        for voxel in voxels {
            if voxel.density < 50 { continue }
            if alreadyRenderedVoxels.contains(voxel) { continue } // To increase rendering efficiency
            print(voxel.density)
            let position = voxel.Position
            let box = SCNBox(width: CGFloat(1 / voxel.scale.x), height: CGFloat(1 / voxel.scale.y), length: CGFloat(1 / voxel.scale.z), chamferRadius: 0)
            box.firstMaterial?.diffuse.contents = position.y < (groundHeight ?? -10) + 0.1 ? UIColor.green :
                UIColor(red: CGFloat(abs(position.y * 800)) / 255, green: 0.2, blue: 0.2, alpha: 1)
            let voxelNode = SCNNode(geometry: box)
            voxelNode.position = SCNVector3(position)
            voxelNodes.append(voxelNode)
            alreadyRenderedVoxels.insert(voxel)
        }
        return voxelNodes
    }

    private func setMinMax() {
        let voxels = voxelSet
        voxels.forEach { voxel in
            xMax = max(voxel.Position.x, xMax ?? -100_000)
            xMin = min(voxel.Position.x, xMin ?? 100_000)
            zMax = max(voxel.Position.z, zMax ?? -100_000)
            zMin = min(voxel.Position.z, zMin ?? 100_000)
        }
    }

    func makeGraph() -> [[Int]]? {
        setMinMax()
        guard let xmax = xMax else { return nil }
        guard let xmin = xMin else { return nil }
        guard let zmax = zMax else { return nil }
        guard let zmin = zMin else { return nil }

        let rows = Int((xmax - xmin) / (1.0 / gridSize))
        let columns = Int((zmax - zmin) / (1.0 / gridSize))
        // var graph = Matrix(rows: rows + 1, columns: columns + 1)
        var graph = Array(repeating: Array(repeating: 2, count: columns + 2), count: rows + 2)
        let voxels = voxelSet
        voxels.forEach { voxel in
            let row = Int((xmax - voxel.Position.x) / (1.0 / gridSize))
            let column = Int((zmax - voxel.Position.z) / (1.0 / gridSize))
            if voxel.Position.y < (groundHeight ?? -10) + 0.4 {
                graph[row][column] = 0
            } else {
                graph[row][column] = 1
            }
        }

        return graph
    }

    func getObstacleGraphDebug() -> UIView {
        guard let matrix = makeGraph() else { return UIView() }
        return MapVisualisation(map: matrix)
    }

    func getObstacleGraphAndPathDebug(start: vector_float3, end _: vector_float3) -> UIView {
        setMinMax()
        guard var matrix = makeGraph() else { return UIView() }
        guard let xmax = xMax else { return UIView() }
        guard let zmax = zMax else { return UIView() }
        let _start = Position(Int((xmax - start.x) / (1.0 / gridSize)),
                              Int((zmax - start.z) / (1.0 / gridSize)))
        let _end = Position(Int((xmax - start.x) / (1.0 / gridSize)),
                            Int((zmax - start.z) / (1.0 / gridSize)))
        let path = Pathfinding.aStarPath(map: matrix, start: _start, end: _end)
        path.forEach { matrix[$0.x][$0.y] = 3 }
        return MapVisualisation(map: matrix)
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
}

extension VoxelMap {
    /// Generate a geometry point cloud out of current Vertices.
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

//
//  voxelMapTests.swift
//  voxelMapTests
//
//  Created by Ferdinand Lösch on 21/10/2019.
//  Copyright © 2019 Ferdinand Lösch. All rights reserved.
//

import simd
@testable import voxelMap
import XCTest

class voxelMapTests: XCTestCase {
    var map: VoxelMap!
    var voxelCount = 0
    override func setUp() {
        // Make a voxel map back.
        super.setUp()

        map = VoxelMap()
        for i in 0 ... 10 {
            map.addVoxel(vector_float3(x: Float(i), y: Float(i), z: Float(i)))
            voxelCount += 1
        }
    }

    override func tearDown() {
        map = nil
        super.tearDown()
    }

    func testCorrectNumberOfVoxelNodes() {
        map.addVoxel(vector_float3(x: 100, y: 100, z: 100))
        voxelCount += 1
        XCTAssertEqual(map.voxelSet.count, voxelCount)
    }

    func testNoDuplicatesVoxels() {
        map.addVoxel(vector_float3(x: 5, y: 5, z: 5))
        XCTAssertEqual(map.voxelSet.count, voxelCount)
    }

    func testNode() {
        let nodes = map.getPointCloudNode()
        XCTAssertNotNil(map.getPointCloudNode().geometry)
    }
}

//
//  testVoxel.swift
//  voxelMapTests
//
//  Created by Ferdinand Lösch on 22/10/2019.
//  Copyright © 2019 Ferdinand Lösch. All rights reserved.
//

import simd
@testable import voxelMap
import XCTest
class testVoxel: XCTestCase {
    func testVoxel() {
        let voxel = Voxel(vector: vector_float3(1, 2, 3), scale: vector_float3(100, 100, 100), density: 1)
        XCTAssertEqual(voxel.density, 1)
        XCTAssertEqual(voxel.Position, vector_float3(1, 2, 3))
    }
    
    
    func testMakeVoxel() {
       
    }

}

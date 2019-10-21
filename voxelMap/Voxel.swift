//
//  Voxel.swift
//  voxelMap
//
//  Created by Ferdinand Lösch on 21/10/2019.
//  Copyright © 2019 Ferdinand Lösch. All rights reserved.
//

import Foundation
import simd

class Voxel: Hashable {
    var vector: vector_float3
    var density: Double
    var level: Double

    init(vector: vector_float3, density: Double, level: Double) {
        self.vector = vector
        self.density = density
        self.level = level
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(vector.x * 499) // value * and large prime number.
        hasher.combine(vector.y * 937)
        hasher.combine(vector.z * 139)
    }
}

extension Voxel: Equatable {
    static func == (lhs: Voxel, rhs: Voxel) -> Bool {
        return lhs.vector == rhs.vector
    }
}

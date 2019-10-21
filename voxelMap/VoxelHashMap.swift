//  VoxelHashMap.swift
//  voxelMap
//
//  Created by Ferdinand Lösch on 21/10/2019.
//  Copyright © 2019 Ferdinand Lösch. All rights reserved.
//

import Foundation

class HashElement<T: Hashable, U> {
    var key: T
    var value: U?

    init(key: T, value: U?) {
        self.key = key
        self.value = value
    }
}

struct HashTable<Key: Voxel, Value> {
    typealias Bucket = [HashElement<Key, Value>]

    var buckets: [Bucket]

    init(capacity: Int) {
        assert(capacity > 0)
        buckets = [Bucket](repeatElement([], count: capacity))
    }

    func hashingIndax(for key: Key) -> Int {
        return key.hashValue % buckets.count
    }

    func value(for key: Key) -> Value? {
        let index = hashingIndax(for: key)
        for element in buckets[index] {
            if element.key == key {
                return element.value
            }
        }
        return nil
    }

    subscript(key: Key) -> Value? {
        get {
            return value(for: key)
        }
        set {
            if let value = newValue {
                updateValue(value, forKey: key)
            } else {
                removeValue(for: key)
            }
        }
    }

    @discardableResult
    mutating func updateValue(_ value: Value, forKey key: Key) -> Value? {
        var itemIndex: Int
        itemIndex = hashingIndax(for: key)
        for (i, element) in buckets[itemIndex].enumerated() {
            if element.key == key {
                let oldValue = element.value
                buckets[itemIndex][i].value = value
                return oldValue
            }
        }
        buckets[itemIndex].append(HashElement(key: key, value: value))
        return nil
    }

    @discardableResult
    mutating func removeValue(for key: Key) -> Value? {
        let index = hashingIndax(for: key)
        for (i, element) in buckets[index].enumerated() {
            if element.key == key {
                buckets[index].remove(at: i)
                return element.value
            }
        }
        return nil
    }
}

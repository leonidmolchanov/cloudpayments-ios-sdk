//
//  SaveCardState.swift
//  Cloudpayments
//
//  Created by Cloudpayments on 08.07.2023.
//

import Foundation

enum SaveCardState {
    case isOnCheckbox
    case isOnHint
    case none
}

struct PatchBuilder {
    private(set) var operations: [[String: Any]] = []

    mutating func replace(_ path: String, value: Any) {
        operations.append([
            "op": "replace",
            "path": path,
            "value": value
        ])
    }

    mutating func add(_ path: String, value: Any) {
        operations.append([
            "op": "add",
            "path": path,
            "value": value
        ])
    }

    mutating func remove(_ path: String) {
        operations.append([
            "op": "remove",
            "path": path
        ])
    }

    func build() -> [[String: Any]] {
        return operations
    }

    static func make(_ builder: (inout PatchBuilder) -> Void) -> [[String: Any]] {
        var patch = PatchBuilder()
        builder(&patch)
        return patch.build()
    }
}

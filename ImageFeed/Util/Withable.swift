//
//  Withable.swift
//  ImageFeed
//
//  Created by JunHwan Kims on 2/22/26.
//

import Foundation

protocol Withable {}

extension Withable {
    func with(_ update: (inout Self) throws -> Void) rethrows -> Self {
        var copy = self
        try update(&copy)
        return copy
    }
}

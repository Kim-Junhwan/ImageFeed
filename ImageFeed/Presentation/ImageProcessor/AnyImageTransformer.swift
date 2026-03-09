//
//  AnyImageTransformer.swift
//  ImageFeed
//
//  Created by JunHwan Kims on 3/2/26.
//

import Foundation
import UIKit

struct AnyImageTransformer<Input, Output> {
    private let _transform: (Input) -> Output
    
    init<T: ImageTransfer>(_ t: T) where T.Input == Input, T.Output == Output {
        self._transform = t.transform
    }
    
    func transform(_ input: Input) -> Output {
        return _transform(input)
    }
}

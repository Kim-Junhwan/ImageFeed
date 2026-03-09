//
//  ImageTransfer.swift
//  ImageFeed
//
//  Created by JunHwan Kims on 3/2/26.
//

import Foundation

protocol ImageTransfer {
    associatedtype Input
    associatedtype Output
    
    func transform(_ input: Input) -> Output
}

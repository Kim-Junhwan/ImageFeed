//
//  ImageDataRepository.swift
//  ImageFeed
//
//  Created by JunHwan Kims on 2/19/26.
//

import Foundation

protocol ImageDataRepository: Sendable {
    func loadImageData(url: URL) async throws -> Data
    func clear() async
}

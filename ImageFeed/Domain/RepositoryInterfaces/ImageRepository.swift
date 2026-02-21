//
//  ImageRepository.swift
//  ImageFeed
//
//  Created by JunHwan Kims on 2/18/26.
//

import Foundation

protocol ImageRepository {
    func fetchImages(page: Int) async throws -> [IFImage]
}

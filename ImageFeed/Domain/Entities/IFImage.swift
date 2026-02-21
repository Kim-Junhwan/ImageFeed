//
//  IFImage.swift
//  ImageFeed
//
//  Created by JunHwan Kims on 2/18/26.
//

import Foundation

struct IFImage {
    let id: String
    let url: URL
    let thumbnailUrl: URL
    let width: Int
    let height: Int
    let author: String
    let createdAt: Date
    let likesCount: Int
    let isLiked: Bool
}

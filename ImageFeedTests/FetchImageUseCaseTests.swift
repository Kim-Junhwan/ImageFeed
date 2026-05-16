//
//  FetchImageUseCaseTests.swift
//  ImageFeedTests
//
//  Created by JunHwan Kims on 5/16/26.
//

import Testing
import Foundation
@testable import ImageFeed

enum TestError: Error {
    case fetchImageError
}

class MockImageRepository: ImageRepository {
    
    var isSuccess: Bool = true
    var stubImages: [IFImage] = []
    var reqPage: Int = -1
    
    func fetchImages(page: Int) async throws -> [IFImage] {
        reqPage = page
        if isSuccess {
            return stubImages
        } else {
            throw TestError.fetchImageError
        }
    }
    
    func setStubImage(_ images: [IFImage]) {
        self.stubImages = images
    }
}


struct FetchImageUseCaseTests {
    
    let mock = MockImageRepository()
    
    func makeImage() -> IFImage {
        return IFImage(id: UUID().uuidString, url: URL(string: "test")!, thumbnailUrl: URL(string: "test")!, width: 0, height: 0, author: "", createdAt: Date(), likesCount: 0, isLiked: false)
    }
    
    func makeSut() -> FetchImageUseCase {
        return FetchImageUseCase(imageRepository: mock)
    }
    
    @Test func fetchImageSuccessTest() async {
        let sut = makeSut()
        mock.isSuccess = true
        mock.setStubImage([makeImage()])
        
        let result = try? await sut.excute(page: 0)
        #expect(mock.reqPage == 0)
        #expect(result?.count == 1)
    }
    
    @Test func fetchImageFailTest() async {
        let sut = makeSut()
        mock.isSuccess = false
        await #expect(throws: TestError.fetchImageError) {
            try await sut.excute(page: 0)
        }
        #expect(mock.reqPage == 0)
    }
}

//
//  ImageFeedViewModelTest.swift
//  ImageFeedTests
//
//  Created by JunHwan Kims on 5/20/26.
//

import Testing
@testable import ImageFeed
import Foundation

class MockImageFeedRepository: ImageRepository {
    
    var stubImages: [ImageFeed.IFImage] = []
    
    func fetchImages(page: Int) async throws -> [ImageFeed.IFImage] {
        await try Task.sleep(nanoseconds: 5000_000)
        return stubImages
    }
    
}

@MainActor
struct ImageFeedViewModelTest {
    
    var mock = MockImageFeedRepository()
    
    func makeImage() -> IFImage {
        return IFImage(id: UUID().uuidString, url: URL(string: "test")!, thumbnailUrl: URL(string: "test")!, width: 0, height: 0, author: "", createdAt: Date(), likesCount: 0, isLiked: false)
    }
    
    func makeSut() -> ImageFeedViewModel {
        return ImageFeedViewModel(fetchImageUseCase: FetchImageUseCase(imageRepository: mock))
    }

    @Test func testFetchImages() async throws {
        let sut = makeSut()
        mock.stubImages = [makeImage(), makeImage()]
        let stream = observe({ return sut.state.images }, { sut.state.images.count == 2 })
        sut.trigger(.loadInital)
        for await _ in stream {}
        #expect(sut.state.images.count == 2)
    }
    
    func observe<T: Sendable>(_ apply: @escaping @MainActor () -> T, _ finishCondition: @escaping @MainActor () -> Bool) -> AsyncStream<T> {
          AsyncStream { continuation in
              @MainActor func track() {
                  withObservationTracking {
                      apply()
                  } onChange: {
                      Task { @MainActor in
                          continuation.yield(apply())
                          if finishCondition() {
                              continuation.finish()
                          } else {
                              track()
                          }
                      }
                  }
              }
              Task { @MainActor in track() }
          }
      }

}

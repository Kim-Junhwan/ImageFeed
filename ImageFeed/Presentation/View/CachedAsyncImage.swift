//
//  CachedAsyncImage.swift
//  ImageFeed
//
//  Created by JunHwan Kims on 2/22/26.
//

import SwiftUI
import UIKit
import Combine
import ImageIO

// MARK: - ImageCache
/// 디코딩·다운샘플된 UIImage를 캐싱하는 프레젠테이션 레이어 캐시.
/// 셀이 LazyVGrid에서 재진입할 때 재디코딩 없이 즉시 표시할 수 있다.
final class ImageCache {
    static let shared = ImageCache()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.totalCostLimit = 100 * 1024 * 1024 // 100MB
    }

    func image(for key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func store(_ image: UIImage, for key: String) {
        // cost = 픽셀 수 × 4바이트(ARGB)
        let cost = Int(image.size.width * image.size.height * image.scale * image.scale) * 4
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }
}

// MARK: - CachedAsyncImage
struct CachedAsyncImage: View {
    let url: URL
    let imageDataRepository: ImageDataRepository
    let targetSize: CGSize

    @StateObject private var loader: ImageLoader

    init(url: URL, imageDataRepository: ImageDataRepository, targetSize: CGSize) {
        self.url = url
        self.imageDataRepository = imageDataRepository
        self.targetSize = targetSize
        _loader = StateObject(wrappedValue: ImageLoader(
            url: url,
            imageDataRepository: imageDataRepository
        ))
    }

    var body: some View {
        Group {
            switch loader.loadState {
            case .loaded(let uiImage):
                Color.clear
                    .background {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    }
            case .failed:
                Color.clear
                    .background(alignment: .center, content: {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    })
            case .idle, .loading:
                Color.clear
                    .background(alignment: .center, content: {
                        ProgressView()
                    })
            }
        }
        .task {
            await loader.load(targetSize: targetSize)
        }
    }
}

// MARK: - LoadState
enum LoadState {
    case idle
    case loading
    case loaded(UIImage)
    case failed(Error)
}

enum ImageLoaderError: Error {
    case decodingFailed
}

// MARK: - ImageLoader
@MainActor
final class ImageLoader: ObservableObject {
    @Published private(set) var loadState: LoadState = .idle

    private let url: URL
    private let imageDataRepository: ImageDataRepository

    init(url: URL, imageDataRepository: ImageDataRepository) {
        self.url = url
        self.imageDataRepository = imageDataRepository
    }

    func load(targetSize: CGSize) async {
        guard case .idle = loadState else { return }

        // 1. UIImage 캐시 히트 → 디코딩 없이 즉시 반환 (objectWillChange #1)
        let cacheKey = url.absoluteString
        if let cached = ImageCache.shared.image(for: cacheKey) {
            loadState = .loaded(cached)
            return
        }

        loadState = .loading  // objectWillChange #1

        do {
            let data = try await imageDataRepository.loadImageData(url: url)
            // 2. 표시 크기로 다운샘플 (백그라운드 스레드)
            // Task.detached는 내부에 실제 suspension point가 없으면 Swift 런타임이
            // 호출 스레드(메인)에서 inline 실행할 수 있으므로 GCD로 백그라운드를 명시적으로 보장한다.
            let scale = UIScreen.main.scale
            let uiImage: UIImage? = await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    continuation.resume(returning: downsampledImage(data: data, targetSize: targetSize, scale: scale))
                }
            }

            if let uiImage {
                // 3. 결과를 UIImage 캐시에 저장 → 셀 재진입 시 재디코딩 생략
                ImageCache.shared.store(uiImage, for: cacheKey)
                loadState = .loaded(uiImage)  // objectWillChange #2
            } else {
                loadState = .failed(ImageLoaderError.decodingFailed)
            }
        } catch {
            loadState = .failed(error)  // objectWillChange #2
        }
        // isLoading = false 제거 → objectWillChange 추가 발행 없음
    }
}

// MARK: - Downsampling
/// ImageIO를 사용해 표시 크기로 직접 디코딩한다.
/// UIImage(data:)와 달리 전체 해상도 버퍼를 생성하지 않으므로
/// 메모리 사용량과 GPU 텍스처 업로드 비용을 대폭 줄인다.
private func downsampledImage(data: Data, targetSize: CGSize, scale: CGFloat) -> UIImage? {
    dispatchPrecondition(condition: .notOnQueue(.main))
    assert(!Thread.isMainThread)
    let maxPixelSize = max(targetSize.width, targetSize.height) * scale
    let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
    guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else { return nil }

    let thumbnailOptions: [CFString: Any] = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceShouldCacheImmediately: true,   // 이 시점에 백그라운드에서 디코딩 완료
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
    ]
    guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions as CFDictionary) else {
        return nil
    }
    return UIImage(cgImage: thumbnail, scale: scale, orientation: .up)
}

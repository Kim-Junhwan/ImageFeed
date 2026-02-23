//
//  CachedAsyncImage.swift
//  ImageFeed
//
//  Created by JunHwan Kims on 2/22/26.
//

import SwiftUI
import Combine

struct CachedAsyncImage: View {
    let url: URL
    let imageDataRepository: ImageDataRepository
    
    @StateObject private var loader: ImageLoader
    
    init(url: URL, imageDataRepository: ImageDataRepository) {
        self.url = url
        self.imageDataRepository = imageDataRepository
        _loader = StateObject(wrappedValue: ImageLoader(
            url: url,
            imageDataRepository: imageDataRepository
        ))
    }
    
    var body: some View {
        Group {
            if let uiImage = loader.image {
                Color.clear
                    .background {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    }
            } else if loader.error != nil {
                Color.clear
                    .background(alignment: .center, content: {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    })
            } else {
                Color.clear
                    .background(alignment: .center, content: {
                        ProgressView()
                    })
            }
        }
        .task {
            await loader.load()
        }
    }
}

// MARK: - ImageLoader
@MainActor
final class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let url: URL
    private let imageDataRepository: ImageDataRepository
    
    init(url: URL, imageDataRepository: ImageDataRepository) {
        self.url = url
        self.imageDataRepository = imageDataRepository
    }
    
    func load() async {
        guard image == nil, !isLoading else { return }
        
        isLoading = true
        error = nil
        
        do {
            let data = try await imageDataRepository.loadImageData(url: url)
            let uiImage = await Task.detached(priority: .userInitiated) {
                UIImage(data: data)
            }.value
            
            self.image = uiImage
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
}

//
//  UnsplashAPIService.swift
//  ImageFeed
//
//  Created by JunHwan Kims on 2/19/26.
//

import Foundation

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case decodingFailed
    case networkError(Error)
}

struct ImageDTO: Decodable {
    let id: String
    let urls: ImageURLs
    let width: Int
    let height: Int
    let user: User
    let likes: Int
    let createdAt: String
    
    struct ImageURLs: Decodable {
        let thumb: String
        let full: String
    }
    
    struct User: Decodable {
        let name: String
    }
    
    enum CodingKeys: String, CodingKey {
        case id, urls, width, height, user, likes
        case createdAt = "created_at"
    }
}

extension ImageDTO {
    func toEntity() -> IFImage? {
        guard let url = URL(string: urls.full), let thumbUrl = URL(string: urls.thumb) else {
            return nil
        }
        return IFImage(
            id: id,
            url: url,
            thumbnailUrl: thumbUrl,
            width: width,
            height: height,
            author: user.name,
            createdAt: createdAt.toDate(),
            likesCount: likes,
            isLiked: false)
    }
}

final class UnsplashAPIService {
    private let baseURL = "https://api.unsplash.com"
    private let accessKey = "UtiGgK8CyvHlis4zHLfMN2D4F6wzhVSbYYJZctVrhlI"
    
    func fetchImages(page: Int, perPage: Int = 30) async throws -> [ImageDTO] {
        var components = URLComponents(string: baseURL + "/photos")
        components?.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "\(perPage)")
        ]
        
        guard let url = components?.url else {
            throw APIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url, timeoutInterval: 30.0)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("Client-ID \(accessKey)", forHTTPHeaderField: "Authorization")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: urlRequest)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }

        do {
            let images = try JSONDecoder().decode([ImageDTO].self, from: data)
            return images
        } catch {
            throw APIError.decodingFailed
        }
    }
}

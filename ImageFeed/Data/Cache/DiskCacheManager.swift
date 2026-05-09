//
//  DiskCacheManager.swift
//  ImageFeed
//
//  Created by JunHwan Kims on 2/19/26.
//

import Foundation
internal import UniformTypeIdentifiers

final actor DiskCacheManager {

    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let maxCacheSize: Int = 200 * 1024 * 1024
    private var currentCacheSize: Int = 0

    init() {
        let cachePath = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = cachePath.appendingPathComponent("ImageCache", conformingTo: .data)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // 배치 패칭으로 readdir 1회만 수행 (attributesOfItem 개별 호출 없음)
        currentCacheSize = (try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        ))?.reduce(0) { sum, url in
            sum + ((try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
        } ?? 0
    }

    func save(_ data: Data, key: String) throws {
        let fileUrl = cacheDirectory.appendingPathComponent(toSafeFileName(key), conformingTo: .data)

        // 동일 키로 덮어쓰기 시 기존 크기 선제 차감
        var existingSize = 0
        if fileManager.fileExists(atPath: fileUrl.path()) {
            existingSize = (try? fileUrl.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            currentCacheSize -= existingSize
        }

        do {
            try data.write(to: fileUrl)
        } catch {
            currentCacheSize += existingSize  // 쓰기 실패 시 복원
            throw error
        }

        currentCacheSize += data.count  // O(1)

        if currentCacheSize > maxCacheSize {
            try evict()
        }
    }

    func load(key: String) async throws -> Data? {
        let fileUrl = cacheDirectory.appendingPathComponent(toSafeFileName(key), conformingTo: .data)
        guard fileManager.fileExists(atPath: fileUrl.path()) else { return nil }

        // 캐시 접근 시간 업데이트
        try? fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: fileUrl.path())

        // blocking I/O를 actor 외부에서 실행하여 직렬화 병목 해소
        return try await Task.detached {
            try Data(contentsOf: fileUrl)
        }.value
    }

    func clear() throws {
        let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        for fileUrl in contents {
            try fileManager.removeItem(at: fileUrl)
        }
        currentCacheSize = 0
    }

    private func evict() throws {
        // [방안 A] readdir 1회에 필요한 모든 속성을 배치 패칭
        let contents = try fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]
        )

        struct FileEntry {
            let url: URL
            let size: Int
            let modDate: Date
        }

        // resourceValues()는 캐시된 값 반환 → 추가 stat() 없음
        let entries: [FileEntry] = contents.compactMap { url in
            guard let values = try? url.resourceValues(
                forKeys: [.fileSizeKey, .contentModificationDateKey]
            ) else { return nil }
            return FileEntry(
                url: url,
                size: values.fileSize ?? 0,
                modDate: values.contentModificationDate ?? .distantPast
            )
        }

        // 추가 I/O 없는 메모리 내 정렬 (LRU)
        let sorted = entries.sorted { $0.modDate < $1.modDate }

        var freedSize = 0
        let targetFreeSize = currentCacheSize - maxCacheSize

        for entry in sorted {
            guard freedSize < targetFreeSize else { break }
            do {
                try fileManager.removeItem(at: entry.url)
                freedSize += entry.size
                currentCacheSize -= entry.size  // 삭제 즉시 반영
            } catch {
                continue  // 개별 삭제 실패는 건너뜀
            }
        }
    }

    private func toSafeFileName(_ str: String) -> String {
        return str
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "?", with: "_")
    }
}

//
//  DiskCacheManagerPerformanceTests.swift
//  ImageFeedTests
//
//  Created by JunHwan Kims on 3/9/26.
//

import XCTest
@testable import ImageFeed

final class DiskCacheManagerPerformanceTests: XCTestCase {

    private var sut: DiskCacheManager!
    private let itemCount = 50
    private let dataSize = 500 * 1024 // 500KB

    override func setUp() async throws {
        try await super.setUp()
        sut = DiskCacheManager()

        let testData = Data(repeating: 0xAB, count: dataSize)
        for i in 0..<itemCount {
            try await sut.save(testData, key: "perf-test-\(i)")
        }
    }

    override func tearDown() async throws {
        try await sut.clear()
        sut = nil
        try await super.tearDown()
    }

    // MARK: - 순차 로드 기준선

    func testSequentialLoadPerformance() {
        measure {
            let expectation = expectation(description: "sequential")
            Task {
                for i in 0..<self.itemCount {
                    _ = try await self.sut.load(key: "perf-test-\(i)")
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 30)
        }
    }

    // MARK: - TaskGroup 동시 로드

    func testConcurrentLoadPerformance() {
        measure {
            let expectation = expectation(description: "concurrent")
            Task {
                await withTaskGroup(of: Data?.self) { group in
                    for i in 0..<self.itemCount {
                        group.addTask {
                            try? await self.sut.load(key: "perf-test-\(i)")
                        }
                    }
                    for await _ in group {}
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 30)
        }
    }

    // MARK: - 직접 비교 출력

    func testPrintTimingComparison() async throws {
        // Sequential
        let seqStart = CFAbsoluteTimeGetCurrent()
        for i in 0..<itemCount {
            _ = try await sut.load(key: "perf-test-\(i)")
        }
        let seqTime = CFAbsoluteTimeGetCurrent() - seqStart

        // Concurrent
        let conStart = CFAbsoluteTimeGetCurrent()
        await withTaskGroup(of: Data?.self) { group in
            for i in 0..<itemCount {
                group.addTask {
                    try? await self.sut.load(key: "perf-test-\(i)")
                }
            }
            for await _ in group {}
        }
        let conTime = CFAbsoluteTimeGetCurrent() - conStart

        let speedup = seqTime / conTime

        print("========== DiskCacheManager Performance ==========")
        print("Items: \(itemCount) × \(dataSize / 1024)KB")
        print("Sequential:  \(String(format: "%.4f", seqTime))s")
        print("Concurrent:  \(String(format: "%.4f", conTime))s")
        print("Speedup factor: \(String(format: "%.2f", speedup))x")
        print("")
        if speedup < 1.2 {
            print("→ Speedup ≈ 1.0x: actor 직렬화로 인한 병목 확인됨")
        } else {
            print("→ Speedup > 1.2x: OS 페이지 캐시 등으로 병목이 미미함")
        }
        print("===================================================")
    }
}

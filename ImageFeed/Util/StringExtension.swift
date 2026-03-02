//
//  StringExtension.swift
//  ImageFeed
//
//  Created by JunHwan Kims on 2/19/26.
//

import Foundation

extension ISO8601DateFormatter {
    static let shared: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()
}

extension String {
    
    func toDate() -> Date {
        guard let date = ISO8601DateFormatter.shared.date(from: self) else { return Date() }
        return date
    }
}

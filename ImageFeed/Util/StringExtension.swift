//
//  StringExtension.swift
//  ImageFeed
//
//  Created by JunHwan Kims on 2/19/26.
//

import Foundation

extension String {
    func toDate() -> Date {
        let dateFormatter = ISO8601DateFormatter()
        guard let date = dateFormatter.date(from: self) else { return Date() }
        return date
    }
}

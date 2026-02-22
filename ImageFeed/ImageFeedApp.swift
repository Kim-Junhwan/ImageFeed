//
//  ImageFeedApp.swift
//  ImageFeed
//
//  Created by JunHwan Kims on 2/18/26.
//

import SwiftUI

@main
struct ImageFeedApp: App {
    
    private let diContainer = DIContainer()
    
    var body: some Scene {
        WindowGroup {
            diContainer.makeImageFeedView()
        }
    }
}

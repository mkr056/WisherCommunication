//
//  WisherApp.swift
//  Wisher
//
//  Created by Artem Mkr on 15.01.2023.
//

import Firebase
import SwiftUI

@main
struct WisherApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

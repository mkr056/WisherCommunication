//
//  ContentView.swift
//  Wisher
//
//  Created by Artem Mkr on 15.01.2023.
//

import SwiftUI

struct ContentView: View {
    
    @AppStorage("log_status") var logStatus: Bool = false
    
    var body: some View {
        // MARK: Redirecting User Based on Log Status
        if logStatus {
            MainView()
        } else {
            LoginView()
        }


    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

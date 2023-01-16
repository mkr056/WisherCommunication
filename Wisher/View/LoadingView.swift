//
//  LoadingView.swift
//  Wisher
//
//  Created by Artem Mkr on 15.01.2023.
//

import SwiftUI

struct LoadingView: View {
    
    @Binding var show: Bool
    
    var body: some View {
        ZStack {
            if show {
                Group {
                    Rectangle()
                        .fill(.primary.opacity(0.25))
                        .ignoresSafeArea()
                    ProgressView()
                        .padding(15)
                        .background(.secondary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: show)
    }
}


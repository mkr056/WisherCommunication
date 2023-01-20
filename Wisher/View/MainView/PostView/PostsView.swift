//
//  PostsView.swift
//  Wisher
//
//  Created by Artem Mkr on 15.01.2023.
//

import SwiftUI

struct PostsView: View {
    @Binding var recentPosts: [Post] // these posts are retrieved from Main View and then get passed in to the reusable posts view for it to display
    let feedOptions: [String] = ["Following", "Recommendations"] // Options for the segmented control
    @State private var feedSelected: String = "Following" // for tracking currently selected option
    var body: some View {
        NavigationStack {
            Group {
                if feedSelected == "Following" {
                    ReusablePostsView(posts: $recentPosts)
                        .hAlign(.center).vAlign(.center)
                } else {
                    ReusablePostsView(posts: .constant([]))
                        .hAlign(.center).vAlign(.center)
                }
            }
            //                .overlay(alignment: .bottomTrailing) {
            //                    Button {
            //                        createNewPost.toggle()
            //                    } label: {
            //                        Image(systemName: "plus")
            //                            .font(.title3)
            //                            .fontWeight(.semibold)
            //                            .foregroundColor(.primary)
            //                            .padding(13)
            //                            .background(.secondary, in: Circle())
            //                    }
            //                    .padding(15)
            //                }
            .navigationTitle("Feed")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("Select Feed", selection: $feedSelected) {
                        ForEach(feedOptions, id: \.self) { option in
                            Text(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .fixedSize()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SearchUserView()
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .tint(.primary)
                            .scaleEffect(0.9)
                    }
                    
                }
            }
        }
    }
}

struct PostsView_Previews: PreviewProvider {
    static var previews: some View {
        PostsView(recentPosts: .constant([]))
    }
}

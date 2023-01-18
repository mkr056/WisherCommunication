//
//  PostsView.swift
//  Wisher
//
//  Created by Artem Mkr on 15.01.2023.
//

import SwiftUI

struct PostsView: View {
    @State private var recentPosts: [Post] = [] // these posts get passed in to the reusable posts view for it to display
    @State private var createNewPost: Bool = false // for triggering create new post view as fullscreen cover
    var body: some View {
        NavigationStack {
            ReusablePostsView(posts: $recentPosts)
                .hAlign(.center).vAlign(.center)
                .overlay(alignment: .bottomTrailing) {
                    Button {
                        createNewPost.toggle()
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .padding(13)
                            .background(.secondary, in: Circle())
                    }
                    .padding(15)
                }
                .toolbar(content: {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink {
                            SearchUserView()
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .tint(.primary)
                                .scaleEffect(0.9)
                        }

                    }
                })
                .navigationTitle("Posts")
        }
        .fullScreenCover(isPresented: $createNewPost) {
            CreateNewPost { post in
                // MARK: Adding Created post at the Top of the Recent Posts
                recentPosts.insert(post, at: 0)
            }
        }
    }
}

struct PostsView_Previews: PreviewProvider {
    static var previews: some View {
        PostsView()
    }
}

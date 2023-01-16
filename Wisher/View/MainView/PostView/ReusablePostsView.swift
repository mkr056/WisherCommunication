//
//  ReusablePostsView.swift
//  Wisher
//
//  Created by Artem Mkr on 16.01.2023.
//

import SwiftUI
import Firebase

struct ReusablePostsView: View {
    var basedOnUID: Bool = false
    var uid: String = ""
    @Binding var posts: [Post]
    // MARK: View Properties
    @State private var isFetching: Bool = true
    
    // MARK: Pagination
    @State private var paginationDoc: QueryDocumentSnapshot?
    
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack {
                if isFetching {
                    ProgressView()
                        .padding(.top, 30)
                } else {
                    if posts.isEmpty {
                        // MARK: No Posts Found on Firestore
                        Text("No Posts Found")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 30)
                        
                    } else {
                        // MARK: Displaying Posts
                        Posts()
                    }
                }
            }
            .padding(15)
        }
        .refreshable {
            // MARK: Scroll To Refresh
            // MARK: Disabling Refresh for UID based Posts
            guard !basedOnUID else { return }
            isFetching = true
            posts.removeAll(keepingCapacity: true)
            // MARK: Reseting Pagination Doc
            paginationDoc = nil
            
            await fetchPosts()
        }
        .task {
            // MARK: Fetching For One Time
            guard posts.isEmpty else { return }
            await fetchPosts()
            
        }
    }
    
    // MARK: Displaying Fetched Posts
    @ViewBuilder
    func Posts() -> some View {
        ForEach(posts) { post in
            PostCardView(post: post) { updatedPost in
                // MARK: Updating Post in the Array
                if let index = posts.firstIndex(where: { post in
                    post.id == updatedPost.id
                }) {
                    posts[index].likedIDs = updatedPost.likedIDs
                    posts[index].dislikedIDs = updatedPost.dislikedIDs

                }
                
            } onDelete: {
                // MARK: Removing Post From the Array
                withAnimation(.easeInOut(duration: 0.25)) {
                    posts.removeAll { post.id == $0.id }
                }
            }
            .onAppear {
                // MARK: When Last Post Appears, Fetching New Post (If there is one)
                if post.id == posts.last?.id && paginationDoc != nil {
                    Task { await fetchPosts() }
                }
            }
            
            Divider()
                .padding(.horizontal, -15)

        }
    }
    
    // MARK: Fetching Posts
    func fetchPosts() async {
        do {
            var query: Query!
            // MARK: Implementing Pagination
            if let paginationDoc {
                query = Firestore.firestore().collection("Posts")
                    .order(by: "publishedDate", descending: true)
                    .start(afterDocument: paginationDoc)
                    .limit(to: 20)
            } else {
                query = Firestore.firestore().collection("Posts")
                    .order(by: "publishedDate", descending: true)
                    .limit(to: 20)
            }
            
            // MARK: New Query For UID Based Document Fetch. Simply Filter the Posts that do not belong to this UID
            if basedOnUID {
                query = query
                    .whereField("userUID", isEqualTo: uid)
            }
            

            let docs = try await query.getDocuments()
            let fetchedPosts = docs.documents.compactMap { doc -> Post? in
                try? doc.data(as: Post.self)
            }
            await MainActor.run(body: {
                posts.append(contentsOf: fetchedPosts)
                paginationDoc = docs.documents.last
                isFetching = false
            })
        } catch {
            print(error.localizedDescription)
        }
    }
}

struct ReusablePostsView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

//
//  ReusablePostsView.swift
//  Wisher
//
//  Created by Artem Mkr on 16.01.2023.
//

import SwiftUI
import Firebase

struct ReusablePostsView: View { // why Reusable: We need to display the current user's posts on the profile screen, and we also need to display that user's posts when searching for another user. By making it a reusable component, we can easily remove lost of redundant codes
    var basedOnUID: Bool = false // to track whether this view is presented on the feed or after performing a search in the user profile
    var uid: String = "" // get the user UID to show relevant posts in the account feed
    @Binding var posts: [Post] // this property receives the posts from the 'recentPosts' variable of the main(wrapper) view to display and also modifies them sending back the changes. This variable contains the results of fetching and passes the results to parent(wrapper) views
    // MARK: View Properties
    @State private var isFetching: Bool = true // for triggering Progress View
    
    // MARK: Pagination
    @State private var paginationDoc: QueryDocumentSnapshot?
    
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack { // by using LazyVStack, it removes the contents when it's moved out of the screen, allowing us to use onAppear() and onDisappear() to get notified when it's actually entering/leaving the screen
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
            paginationDoc = nil // we must set paginationDoc to nil when the user refreshes the posts since the user's refresh will begin with the most recently written posts and if the pagination doc hasn't been updated, will get the most recent documents
            
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
                if post.id == posts.last?.id && paginationDoc != nil { // why check pagination document isn't nil? Consider that there are 40 posts total, and that the initial fetch fetched 20 posts, with the pagination document being the 20th post, and that when the last post appears, it fetches the next set of 20 posts, with the pagination document being the 40th post. When it tries to fetch another set of 20 posts, it will be empty because there are no more posts available, so paginationDoc will be nil and it will no longer try to fetch the posts
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
            if basedOnUID { // check whether to fetch the recent posts or posts for a given user UID
                query = query
                    .whereField("userUID", isEqualTo: uid)
            }
            

            let docs = try await query.getDocuments()
            let fetchedPosts = docs.documents.compactMap { doc -> Post? in
                try? doc.data(as: Post.self)
            }
            await MainActor.run(body: {
                posts.append(contentsOf: fetchedPosts)
                paginationDoc = docs.documents.last // saving the last fetched document so that it can be used for pagination in the Firebase Firestore
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

//
//  PostCardView.swift
//  Wisher
//
//  Created by Artem Mkr on 16.01.2023.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseStorage

struct PostCardView: View {
    var post: Post
    // MARK: Callbacks
    var onUpdate: (Post) -> ()
    var onDelete: () -> ()
    // MARK: View Properties
    @AppStorage("user_UID") private var userUID: String = ""
    @State private var docListener: ListenerRegistration? // for live updates
    
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            WebImage(url: post.userProfileURL)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 35, height: 35)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6) {
                Text(post.userName)
                    .font(.callout)
                    .fontWeight(.semibold)
                Text(post.publishedDate.formatted(date: .numeric, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text(post.text)
                    .textSelection(.enabled)
                    .padding(.vertical, 8)
                
                // MARK: Post Image If Any
                if let postImageURL = post.imageURL {
                    GeometryReader {
                        let size = $0.size
                        WebImage(url: postImageURL)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.width, height: size.height)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .frame(height: 200)
                }
                PostInteraction()
            }
        }
        .hAlign(.leading)
        .overlay(alignment: .topTrailing, content: {
            // MARK: Displaying Delete Button (if it's Author of that post)
            if post.userUID == userUID {
                Menu {
                    Button("Delete Post", role: .destructive, action: deletePost)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .rotationEffect(.init(degrees: -90))
                        .foregroundColor(.black)
                        .padding(8)
                        .contentShape(Rectangle())
                }
                .offset(x: 8)

            }
        })
        .onAppear {
            // MARK: Adding Only Once
            if docListener == nil {
                guard let postID = post.id else { return }
                docListener = Firestore.firestore().collection("Posts").document(postID).addSnapshotListener({ snapshot, error in
                    if let snapshot {
                        if snapshot.exists {
                            // MARK: Document Updated, Fetching Updated Document
                            if let updatedPost = try? snapshot.data(as: Post.self) {
                                onUpdate(updatedPost)
                            }
                            
                        } else {
                            // MARK: Document Deleted
                            onDelete()
                        }
                    }
                })
            }
        }
        .onDisappear {
            // MARK: Applying Snapshot Listener Only When the Post is Available on the Screen. Else Removing the Listener (it saves unwanted live updates from the posts which were swiped away from the screen)
            if let docListener {
                docListener.remove()
                self.docListener = nil
            }
        }
    }
    // MARK: Like/Dislike Interaction
    @ViewBuilder
    func PostInteraction() -> some View {
        HStack(spacing: 6) {
            Button(action: likePost) {
                Image(systemName: post.likedIDs.contains(userUID) ? "hand.thumbsup.fill" : "hand.thumbsup")
            }
            
            Text("\(post.likedIDs.count)")
                .font(.caption)
                .foregroundColor(.gray)
            
            Button(action: dislikePost) {
                Image(systemName: post.dislikedIDs.contains(userUID) ? "hand.thumbsdown.fill" : "hand.thumbsdown")
            }
            .padding(.leading, 25)
            
            Text("\(post.dislikedIDs.count)")
                .font(.caption)
                .foregroundColor(.gray)

        }
        .foregroundColor(.black)
        .padding(.vertical, 8)
    }
    
    // MARK: Liking Post
    func likePost() {
        Task {
            guard let postID = post.id else { return }
            if post.likedIDs.contains(userUID) {
                // MARK: Removing User ID From the Array
                try await Firestore.firestore().collection("Posts").document(postID).updateData([
                    "likedIDs": FieldValue.arrayRemove([userUID])
                ])
            } else {
                // MARK: Adding User ID To Liked Array and Removing our ID from Disliked Array (if Added in prior)
                try await Firestore.firestore().collection("Posts").document(postID).updateData([
                    "likedIDs": FieldValue.arrayUnion([userUID]),
                    "dislikedIDs": FieldValue.arrayRemove([userUID])
                ])
            }
        }
    }
    
    // MARK: Disliking Post
    func dislikePost() {
        Task {
            guard let postID = post.id else { return }
            if post.dislikedIDs.contains(userUID) {
                // MARK: Removing User ID From the Array
                try await Firestore.firestore().collection("Posts").document(postID).updateData([
                    "dislikedIDs": FieldValue.arrayRemove([userUID])
                ])
            } else {
                // MARK: Adding User ID To Liked Array and Removing our ID from Disliked Array (if Added in prior)
                try await Firestore.firestore().collection("Posts").document(postID).updateData([
                    "likedIDs": FieldValue.arrayRemove([userUID]),
                    "dislikedIDs": FieldValue.arrayUnion([userUID])
                ])
            }
        }
    }
    
    // MARK: Deleting Post
    func deletePost() {
        Task {
            // Step 1: Delete Image from Firebase Storage if present
            do {
                if !post.imageReferenceID.isEmpty {
                    try await Storage.storage().reference().child("Post_Images").child(post.imageReferenceID).delete()
                }
                // Step 2: Delete Firestore Document
                guard let postID = post.id else { return }
                try await Firestore.firestore().collection("Posts").document(postID).delete()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}
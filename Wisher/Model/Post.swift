//
//  Post.swift
//  Wisher
//
//  Created by Artem Mkr on 15.01.2023.
//

import SwiftUI
import FirebaseFirestoreSwift

// MARK: Post Model

struct Post: Identifiable, Codable, Equatable, Hashable {
    @DocumentID var id: String?
    
    // Post content
    var text: String
    
    // Post image url (if uploaded)
    var imageURL: URL?
    
    // Image reference ID (Used for Deletion)
    var imageReferenceID: String = ""
    
    var publishedDate: Date = Date()
    
    // People's user IDs who liked or disliked
    var likedIDs: [String] = []
    var dislikedIDs: [String] = []
    
    // Post Author's basic info (for Post View)
    var userName: String
    var userUID: String
    var userProfileURL: URL
    
    enum CodingKeys: CodingKey {
        case id, text, imageURL, imageReferenceID, publishedDate, likedIDs, dislikedIDs, userName, userUID, userProfileURL
    }
}

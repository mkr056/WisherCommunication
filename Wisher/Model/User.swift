//
//  User.swift
//  Wisher
//
//  Created by Artem Mkr on 15.01.2023.
//

import SwiftUI
import FirebaseFirestoreSwift

// MARK: User Firestore Object
struct User: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var username: String
    var userBio: String
    var userBioLink: String
    var userUID: String
    var userEmail: String
    var userProfileURL: URL
    var followerIDs: [String] = []
    var followingIDs: [String] = []

    enum CodingKeys: CodingKey {
        case id, username, userBio, userBioLink, userUID, userEmail, userProfileURL, followerIDs, followingIDs
    }
}


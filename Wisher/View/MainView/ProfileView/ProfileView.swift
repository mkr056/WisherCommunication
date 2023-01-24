//
//  ProfileView.swift
//  Wisher
//
//  Created by Artem Mkr on 15.01.2023.
//

import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore

struct ProfileView: View {
    
    // MARK: My Profile Data
    @State private var myProfile: User? // storing the user object (and info) for currently signed in user
    @AppStorage("log_status") var logStatus: Bool = false // getting the current logStatus of the current user
    
    // MARK: View Properties
    @State private var showError = false // for triggering an error alert
    @State private var errorMessage: String = "" // for storing error message in the alert
    @State private var isLoading: Bool = false // for triggering Loading View
    
    var body: some View {
        NavigationStack {
            VStack {
                if let myProfile {
                    ReusableProfileContent(user: myProfile)
                        .refreshable {
                            // MARK: Refresh User Data
                            self.myProfile = nil
                            await fetchUserData()
                        }
                } else {
                    ProgressView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        // MARK: Two Actions
                        // 1. Logout
                        // 2. Delete Account
                        Section {
                            Button("Logout", action: logOutUser)
                            
                            Button("Delete Account", role: .destructive, action: deleteAccount)
                        }
                        
                        Button("Settings", action: {})
                        
                        Button("Edit profile", action: {})
                        
                        Button("Archive", action: {})
                        
                        Button("Copy link", action: {})
                        
                        Button("Share profile", action: {})
                        
                        Button("Logout", action: {})
                        
                        
                        
                    } label: {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.init(degrees: 90))
                            .tint(.primary)
                            .scaleEffect(0.8)
                    }
                }
            }
        }
        .overlay {
            LoadingView(show: $isLoading)
        }
        .alert(errorMessage, isPresented: $showError) {
            
        }
        .task {
            // This Modifier is like onAppear, so Fetching for the First Time Only.
            // Since Task is an alternative to onAppear, which is an async call, whenever the tab is changed and reopened, it will be called like onAppear. That's why we're limiting it to the initial fetch (First time).
            if myProfile != nil { return }
            
            // MARK: Initial Fetch
            await fetchUserData()
        }
    }
    
    // MARK: Fetching User Data
    func fetchUserData() async {
        guard let userUID = Auth.auth().currentUser?.uid else { return }
        guard let user = try? await Firestore.firestore().collection("Users").document(userUID).getDocument(as: User.self) else { return }
        await MainActor.run(body: {
            myProfile = user
        })
        
    }
    
    // MARK: Logging User Out
    func logOutUser() {
        try? Auth.auth().signOut()
        logStatus = false
    }
    
    // MARK: Deleting User Entire Account
    func deleteAccount() {
        isLoading = true
        Task {
            do {
                guard let userUID = Auth.auth().currentUser?.uid else { return }
                // Step 1: First Deleting Profile Image From Storage.
                let reference = Storage.storage().reference().child("Profile_Images").child(userUID)
                try await reference.delete()
                // Step 2: Deleting Firestore User Document.
                try await Firestore.firestore().collection("Users").document(userUID).delete()
                // Step 3: Deleting Auth Account and Setting Log Status to False.
                try await Auth.auth().currentUser?.delete()
                logStatus = false
            } catch {
                await setError(error)
            }

            
        }
    }
    
    // MARK: Setting Error
    func setError(_ error: Error) async {
        // MARK: UI Must be run On Main Thread
        await MainActor.run(body: {
            isLoading = false
            errorMessage = error.localizedDescription
            showError.toggle()
        })
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}

//
//  MainView.swift
//  Wisher
//
//  Created by Artem Mkr on 15.01.2023.
//

import SwiftUI

struct MainView: View {
    
    // MARK: View Properties
    @State private var selectedIndex = 0
    let tabBarImageNames = ["rectangle.portrait.on.rectangle.portrait.angled", "plus.circle.fill", "gear"]
    @State private var createNewPost: Bool = false
    @State private var recentPosts: [Post] = [] // these posts get passed in to the PostsView posts view for it to send to ReusablePostView where they are being presented. All the changes applied are pushed back to this view, therefore are being updated. This functionality proves the feature of updating feed when post is added.
    @State private var recommendationPosts: [Post] = []


    var body: some View {
        // MARK: TabView With Recent Posts And Profile Tabs
        VStack(spacing: 0) {
            ZStack {
                switch selectedIndex {
                case 0:
                    PostsView(recentPosts: $recentPosts, recommendationPosts: $recommendationPosts)

                case 2:
                    ProfileView()
                default:
                    Text("Remaining Tabs")
                }
            }
            Divider()
                .padding(.bottom, 8)
            HStack {
                ForEach(0..<3) { num in
                    
                    Button {
                        if num == 1 {
                            createNewPost.toggle()
                            return
                        }
                        selectedIndex = num
                    } label: {
                        Spacer()
                        if num == 1 {
                            Image(systemName: tabBarImageNames[num])
                                .font(.title)
                                .foregroundColor(.red)
                        } else {
                            Image(systemName: tabBarImageNames[num])
                                .font(.title)
                                .foregroundColor(selectedIndex == num ? .primary : .init(white: 0.8))
                        }
                        Spacer()
                    }


                }
            }
            
        }
        .fullScreenCover(isPresented: $createNewPost) {
            CreateNewPost { post in
                recentPosts.insert(post, at: 0)
                selectedIndex = 0
            }
        }
        
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}



//        // MARK: TabView With Recent Posts And Profile Tabs
//        TabView {
//           PostsView()
//                .tabItem {
//                    Image(systemName: "rectangle.portrait.on.rectangle.portrait.angled")
//                    Text("Posts")
//                }
//
//            ProfileView()
//                .tabItem {
//                    Image(systemName: "gear")
//                    Text("Profile")
//                }
//        }
//        // MARK: Changing Tab Label Tint to Black
//        .tint(.primary)

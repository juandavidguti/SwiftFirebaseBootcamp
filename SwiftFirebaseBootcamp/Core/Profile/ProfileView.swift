//
//  ProfileView.swift
//  SwiftFirebaseBootcamp
//
//  Created by Juan David Gutierrez Olarte on 29/09/25.
//

import SwiftUI
import PhotosUI
import Shimmer

struct ProfileView: View {
    
    @StateObject private var viewModel = ProfileViewModel()
    @Binding var showSignInView: Bool
    let preferencesOptions: [String] = ["Sports","Movies","Books"]
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var url: URL? = nil
    @State private var isShimmering: Bool = true
    
    private func preferenceIsSelected(text: String) -> Bool {
        viewModel.user?.preferences?.contains(text) == true
    }
    
    var body: some View {
        List {
            if let user = viewModel.user {
                Text("UserId: \(user.userId)")
                
                if let isAnonymous = user.isAnonymous {
                    Text("Anonymous: \(isAnonymous ? "Yes" : "No")")
                }
                
                Button {
                    viewModel.togglePremiumStatus()
                } label: {
                    Text(
                        "User is premium: \((user.isPremium ?? false).description.capitalized)")
                }
                VStack {
                    HStack {
                        ForEach(preferencesOptions, id: \.self) { string in
                            Button(string) {
                                if preferenceIsSelected(text: string) {
                                    viewModel.removeUserPreference(text: string)
                                } else {
                                    viewModel.addUserPreference(text: string)
                                }
                            }
                            .font(.headline)
                            .buttonStyle(.borderedProminent)
                            .tint(preferenceIsSelected(text: string) ? .green : .red)
                        }
                    }
                    Text(
                        "Users preferences: \((user.preferences ?? []).joined(separator: ","))")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Button {
                    if user.favoriteMovie == nil {
                        viewModel.addFavoriteMovie()
                    } else {
                        viewModel.removeFavoriteMovie()
                    }
                } label: {
                    Text(
                        "Favorite Movie: \((user.favoriteMovie?.title ?? ""))")
                }
                // calling function
                PhotosPicker(selection: $selectedItem, matching: .images, preferredItemEncoding: .automatic, photoLibrary: .shared()) {
                    Text("Select a photo")
                }
                
                if let urlString = viewModel.user?.profileImagePathUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 150, height: 150)
                            .cornerRadius(10)
                    } placeholder: {
                        ShimmerAvatar(isShimmering: $isShimmering)
                    }
                } else {
                    // Simulate loading state even if we don't have permission/URL yet
                    ShimmerAvatar(isShimmering: $isShimmering)
                }
                if viewModel.user?.profileImagePathUrl != nil {
                    Button("Delete Image") {
                        viewModel.deleteProfileImage()
                    }
                }
            }
        }
        
        .task {
            try? await viewModel.loadCurrentUser()
            
        }
        // observing change of selecteditem state
        .onChange(of: selectedItem, { _, newValue in
            if let newValue {
                viewModel.saveProfileImage(item: newValue)
            }
        })
        .navigationTitle("Profile")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView(showSignInView: $showSignInView)
                } label: {
                    Image(systemName: "gear")
                        .font(.headline)
                }
                
            }
        }
    }
}

// Helper view for shimmer avatar placeholder
private struct ShimmerAvatar: View {
    @Binding var isShimmering: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(.gray.opacity(0.3))
            .frame(width: 150, height: 150)
            .redacted(reason: .placeholder)
            .shimmering(active: isShimmering)
            .task {
                // Simulate a short loading period; then freeze the skeleton (no shimmer)
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                isShimmering = false
            }
            .accessibilityLabel("Profile image loading placeholder")
    }
}

#Preview {
    NavigationStack {
        RootView()
    }
}

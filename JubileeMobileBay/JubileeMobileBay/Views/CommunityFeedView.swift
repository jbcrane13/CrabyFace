//
//  CommunityFeedView.swift
//  JubileeMobileBay
//
//  Created on 1/19/25.
//

import SwiftUI
import MapKit

struct CommunityFeedView: View {
    @StateObject private var viewModel: CommunityFeedViewModel
    @State private var selectedPost: CommunityPost?
    @State private var showingFilters = false
    @State private var showingCreatePost = false
    @State private var showingLoginPrompt = false
    @EnvironmentObject var authenticationService: AuthenticationService
    
    init(cloudKitService: CloudKitService) {
        _viewModel = StateObject(wrappedValue: CommunityFeedViewModel(cloudKitService: cloudKitService))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.posts.isEmpty && viewModel.isLoading {
                    loadingView
                } else if viewModel.posts.isEmpty && !viewModel.isLoading {
                    emptyStateView
                } else {
                    feedList
                }
            }
            .navigationTitle("Community Feed")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    createPostButton
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    filterButton
                }
            }
            .sheet(isPresented: $showingFilters) {
                FilterSheet(
                    selectedMarineLife: $viewModel.selectedMarineLifeFilter,
                    sortOption: $viewModel.sortOption
                )
            }
            .sheet(item: $selectedPost) { post in
                PostDetailView(post: post, viewModel: viewModel)
            }
            .sheet(isPresented: $showingCreatePost) {
                ReportView()
            }
            .sheet(isPresented: $showingLoginPrompt) {
                LoginView(authenticationService: authenticationService)
            }
            .task {
                await viewModel.loadPosts()
            }
            .refreshable {
                await viewModel.refresh()
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error)
                }
            }
        }
    }
    
    // MARK: - Views
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading community posts...")
                .foregroundColor(.secondary)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No Community Posts Yet")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Be the first to share a jubilee sighting!")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private var feedList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.filteredPosts) { post in
                    PostCard(post: post)
                        .onTapGesture {
                            selectedPost = post
                        }
                        .onAppear {
                            if post == viewModel.filteredPosts.last {
                                Task {
                                    await viewModel.loadMoreIfNeeded()
                                }
                            }
                        }
                }
                
                if viewModel.isLoadingMore {
                    ProgressView()
                        .padding()
                }
            }
            .padding()
        }
    }
    
    private var createPostButton: some View {
        Button {
            if authenticationService.isAuthenticated {
                showingCreatePost = true
            } else {
                showingLoginPrompt = true
            }
        } label: {
            Image(systemName: "plus.circle.fill")
                .foregroundColor(.blue)
        }
    }
    
    private var filterButton: some View {
        Button {
            showingFilters = true
        } label: {
            HStack {
                Image(systemName: "line.3.horizontal.decrease.circle")
                if viewModel.selectedMarineLifeFilter != nil {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .offset(x: -8, y: -8)
                }
            }
        }
    }
}

// MARK: - Post Card

struct PostCard: View {
    let post: CommunityPost
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(post.userName.prefix(1).uppercased())
                            .font(.headline)
                            .foregroundColor(.blue)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.userName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(post.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Title and Description
            Text(post.title)
                .font(.headline)
                .lineLimit(2)
            
            Text(post.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            // Photos Preview
            if post.hasPhotos {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(post.photoURLs.prefix(3), id: \.self) { photoURL in
                            AsyncImage(url: URL(string: photoURL)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.2))
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        if post.photoURLs.count > 3 {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.black.opacity(0.6))
                                    .frame(width: 100, height: 100)
                                
                                Text("+\(post.photoURLs.count - 3)")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            }
            
            // Marine Life Tags
            if !post.marineLifeTypes.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(post.marineLifeTypes), id: \.self) { type in
                            MarineLifeTag(type: type)
                        }
                    }
                }
            }
            
            // Interaction Bar
            HStack(spacing: 20) {
                Button {
                    // Like action handled in detail view
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: post.isLikedByCurrentUser ? "heart.fill" : "heart")
                            .foregroundColor(post.isLikedByCurrentUser ? .red : .secondary)
                        Text("\(post.likeCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
                
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left")
                        .foregroundColor(.secondary)
                    Text("\(post.commentCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "location.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Marine Life Tag

struct MarineLifeTag: View {
    let type: MarineLifeType
    
    var body: some View {
        Text(type.displayName)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .clipShape(Capsule())
    }
}

// MARK: - Filter Sheet

struct FilterSheet: View {
    @Binding var selectedMarineLife: MarineLifeType?
    @Binding var sortOption: CommunityFeedViewModel.SortOption
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Filter by Marine Life") {
                    ForEach(MarineLifeType.allCases, id: \.self) { type in
                        HStack {
                            Text(type.displayName)
                            Spacer()
                            if selectedMarineLife == type {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedMarineLife == type {
                                selectedMarineLife = nil
                            } else {
                                selectedMarineLife = type
                            }
                        }
                    }
                }
                
                Section("Sort By") {
                    ForEach(CommunityFeedViewModel.SortOption.allCases, id: \.self) { option in
                        HStack {
                            Text(option.rawValue)
                            Spacer()
                            if sortOption == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            sortOption = option
                        }
                    }
                }
                
                if selectedMarineLife != nil {
                    Section {
                        Button("Clear Filter") {
                            selectedMarineLife = nil
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Post Detail View

struct PostDetailView: View {
    let post: CommunityPost
    let viewModel: CommunityFeedViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingMap = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text(post.userName.prefix(1).uppercased())
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            )
                        
                        VStack(alignment: .leading) {
                            Text(post.userName)
                                .font(.headline)
                            Text(post.formattedDate)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Content
                    VStack(alignment: .leading, spacing: 12) {
                        Text(post.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(post.description)
                            .font(.body)
                    }
                    .padding(.horizontal)
                    
                    // Photos
                    if post.hasPhotos {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(post.photoURLs, id: \.self) { photoURL in
                                    AsyncImage(url: URL(string: photoURL)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                    } placeholder: {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(height: 200)
                                            .overlay(
                                                ProgressView()
                                            )
                                    }
                                    .frame(maxHeight: 300)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Location
                    Button {
                        showingMap = true
                    } label: {
                        HStack {
                            Image(systemName: "map")
                            Text("View Location")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.horizontal)
                    
                    // Marine Life
                    if !post.marineLifeTypes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Marine Life Observed")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(Array(post.marineLifeTypes), id: \.self) { type in
                                        MarineLifeTag(type: type)
                                            .scaleEffect(1.2)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Interaction Bar
                    HStack(spacing: 30) {
                        Button {
                            Task {
                                await viewModel.toggleLike(for: post)
                            }
                        } label: {
                            VStack {
                                Image(systemName: post.isLikedByCurrentUser ? "heart.fill" : "heart")
                                    .font(.title2)
                                    .foregroundColor(post.isLikedByCurrentUser ? .red : .primary)
                                Text("\(post.likeCount)")
                                    .font(.caption)
                            }
                        }
                        
                        VStack {
                            Image(systemName: "bubble.left")
                                .font(.title2)
                            Text("\(post.commentCount)")
                                .font(.caption)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingMap) {
                CommunityLocationMapView(coordinate: post.location, title: post.title)
            }
        }
    }
}

// MARK: - Location Map View

struct CommunityLocationMapView: View {
    let coordinate: CLLocationCoordinate2D
    let title: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Map(position: .constant(.region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )))) {
                Marker(title, coordinate: coordinate)
            }
            .navigationTitle("Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
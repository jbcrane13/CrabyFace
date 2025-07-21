//
//  PhotoPickerView.swift
//  JubileeMobileBay
//
//  Photo picker view with multi-selection and preview
//

import SwiftUI
import PhotosUI

struct PhotoPickerView: View {
    @ObservedObject var viewModel: ReportViewModel
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isLoadingPhotos = false
    
    private let maxPhotos = 5
    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 10)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Label("Photos", systemImage: "photo.on.rectangle.angled")
                    .font(.headline)
                
                Spacer()
                
                if viewModel.photos.count > 0 {
                    Text("\(viewModel.photos.count)/\(maxPhotos)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Photo grid
            if !viewModel.photos.isEmpty {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(viewModel.photos) { photo in
                        PhotoThumbnailView(
                            photo: photo,
                            onDelete: {
                                viewModel.removePhoto(photo)
                            }
                        )
                    }
                }
            }
            
            // Add photos button
            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: maxPhotos - viewModel.photos.count,
                matching: .images
            ) {
                Label(
                    viewModel.photos.isEmpty ? "Add Photos" : "Add More Photos",
                    systemImage: "plus.circle.fill"
                )
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(10)
            }
            .disabled(viewModel.photos.count >= maxPhotos || isLoadingPhotos)
            
            if isLoadingPhotos {
                ProgressView("Loading photos...")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .onChange(of: selectedItems) { items in
            Task {
                await loadPhotos(from: items)
            }
        }
    }
    
    private func loadPhotos(from items: [PhotosPickerItem]) async {
        isLoadingPhotos = true
        defer { isLoadingPhotos = false }
        
        for item in items {
            if let photoItem = await viewModel.loadPhoto(from: item) {
                await MainActor.run {
                    viewModel.addPhotos([photoItem])
                }
            }
        }
        
        // Clear selection
        selectedItems = []
    }
}

// MARK: - Photo Thumbnail View

struct PhotoThumbnailView: View {
    let photo: PhotoItem
    let onDelete: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Photo
            Group {
                if let image = photo.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipped()
                        .cornerRadius(8)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .overlay(
                            ProgressView()
                        )
                }
            }
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .padding(4)
        }
    }
}

// MARK: - Preview

#Preview {
    PhotoPickerView(viewModel: ReportViewModel())
        .padding()
}
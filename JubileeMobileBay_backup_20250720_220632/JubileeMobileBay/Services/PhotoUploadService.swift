//
//  PhotoUploadService.swift
//  JubileeMobileBay
//
//  Handles photo uploads to CloudKit Assets with retry and optimization
//

import Foundation
import SwiftUI
import UIKit
import CloudKit
import Photos
import PhotosUI

// MARK: - Photo Upload Error

enum PhotoUploadError: LocalizedError {
    case imageProcessingFailed
    case compressionFailed
    case uploadFailed(String)
    case assetNotFound
    case permissionDenied
    case quotaExceeded
    case invalidImage
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Failed to process image"
        case .compressionFailed:
            return "Failed to compress image"
        case .uploadFailed(let reason):
            return "Upload failed: \(reason)"
        case .assetNotFound:
            return "Photo asset not found"
        case .permissionDenied:
            return "Photo library access denied"
        case .quotaExceeded:
            return "Upload quota exceeded"
        case .invalidImage:
            return "Invalid image format"
        }
    }
}

// MARK: - Photo Upload Result

struct PhotoUploadResult {
    let photoReference: PhotoReference
    let asset: CKAsset
    let thumbnailAsset: CKAsset?
}

// MARK: - Photo Upload Service

@MainActor
final class PhotoUploadService: ObservableObject {
    
    // MARK: - Properties
    
    private let container: CKContainer
    private let publicDatabase: CKDatabase
    private let maxImageSize: CGFloat = 2048
    private let thumbnailSize: CGFloat = 200
    private let compressionQuality: CGFloat = 0.8
    
    @Published var uploadProgress: Double = 0
    @Published var isUploading = false
    @Published var uploadErrors: [PhotoUploadError] = []
    
    // MARK: - Initialization
    
    init(container: CKContainer? = nil) {
        self.container = container ?? CKContainer(identifier: "iCloud.com.jubileemobilebay.container")
        self.publicDatabase = self.container.database(with: .public)
    }
    
    // MARK: - Upload Methods
    
    func uploadPhotos(from items: [PhotosPickerItem]) async throws -> [PhotoReference] {
        isUploading = true
        uploadProgress = 0
        uploadErrors = []
        defer { isUploading = false }
        
        var uploadedReferences: [PhotoReference] = []
        let totalItems = Double(items.count)
        
        for (index, item) in items.enumerated() {
            do {
                // Load image data
                guard let imageData = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: imageData) else {
                    throw PhotoUploadError.assetNotFound
                }
                
                // Upload with retry
                let reference = try await uploadImageWithRetry(image: image, index: index)
                uploadedReferences.append(reference)
                
                // Update progress
                uploadProgress = Double(index + 1) / totalItems
                
            } catch {
                uploadErrors.append(error as? PhotoUploadError ?? .uploadFailed(error.localizedDescription))
                continue
            }
        }
        
        return uploadedReferences
    }
    
    private func uploadImageWithRetry(image: UIImage, index: Int, retryCount: Int = 0) async throws -> PhotoReference {
        do {
            return try await uploadImage(image: image, index: index)
        } catch {
            // Retry logic for transient failures
            if retryCount < 3 && isRetryableError(error) {
                let delay = TimeInterval(pow(2.0, Double(retryCount))) // Exponential backoff
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await uploadImageWithRetry(image: image, index: index, retryCount: retryCount + 1)
            }
            throw error
        }
    }
    
    private func isRetryableError(_ error: Error) -> Bool {
        if let ckError = error as? CKError {
            switch ckError.code {
            case .networkUnavailable, .networkFailure, .serviceUnavailable:
                return true
            default:
                return false
            }
        }
        return false
    }
    
    private func uploadImage(image: UIImage, index: Int) async throws -> PhotoReference {
        // Process and compress image
        let processedImage = try processImage(image)
        let thumbnailImage = try createThumbnail(from: image)
        
        // Create temporary files
        let imageURL = try saveImageToTempFile(processedImage, name: "photo_\(index)")
        let thumbnailURL = try saveImageToTempFile(thumbnailImage, name: "thumb_\(index)")
        
        defer {
            // Clean up temp files
            try? FileManager.default.removeItem(at: imageURL)
            try? FileManager.default.removeItem(at: thumbnailURL)
        }
        
        // Create CKAssets
        let imageAsset = CKAsset(fileURL: imageURL)
        let thumbnailAsset = CKAsset(fileURL: thumbnailURL)
        
        // Create record
        let record = CKRecord(recordType: "Photo")
        record["fullImage"] = imageAsset
        record["thumbnail"] = thumbnailAsset
        record["uploadDate"] = Date()
        record["width"] = Int(processedImage.size.width)
        record["height"] = Int(processedImage.size.height)
        
        // Save to CloudKit
        let savedRecord = try await publicDatabase.save(record)
        
        // Create photo reference
        let photoReference = PhotoReference(
            id: UUID(),
            url: imageAsset.fileURL!,
            thumbnailUrl: thumbnailAsset.fileURL!
        )
        
        return photoReference
    }
    
    // MARK: - Image Processing
    
    private func processImage(_ image: UIImage) throws -> UIImage {
        // Validate image
        guard image.size.width > 0 && image.size.height > 0 else {
            throw PhotoUploadError.invalidImage
        }
        
        // Calculate new size maintaining aspect ratio
        let scale = min(maxImageSize / image.size.width, maxImageSize / image.size.height)
        let newSize: CGSize
        
        if scale < 1 {
            newSize = CGSize(
                width: image.size.width * scale,
                height: image.size.height * scale
            )
        } else {
            newSize = image.size
        }
        
        // Resize and compress
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: newSize))
        
        guard let resizedImage = UIGraphicsGetImageFromCurrentImageContext() else {
            throw PhotoUploadError.imageProcessingFailed
        }
        
        return resizedImage
    }
    
    private func createThumbnail(from image: UIImage) throws -> UIImage {
        let scale = min(thumbnailSize / image.size.width, thumbnailSize / image.size.height)
        let newSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: newSize))
        
        guard let thumbnail = UIGraphicsGetImageFromCurrentImageContext() else {
            throw PhotoUploadError.imageProcessingFailed
        }
        
        return thumbnail
    }
    
    private func saveImageToTempFile(_ image: UIImage, name: String) throws -> URL {
        guard let data = image.jpegData(compressionQuality: compressionQuality) else {
            throw PhotoUploadError.compressionFailed
        }
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("\(name)_\(UUID().uuidString).jpg")
        
        try data.write(to: fileURL)
        return fileURL
    }
    
    // MARK: - Batch Upload
    
    func uploadReportPhotos(for report: UserReport, images: [UIImage]) async throws -> [PhotoReference] {
        var references: [PhotoReference] = []
        
        // Upload in batches to avoid memory issues
        let batchSize = 3
        for batchStart in stride(from: 0, to: images.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, images.count)
            let batch = Array(images[batchStart..<batchEnd])
            
            try await withThrowingTaskGroup(of: PhotoReference.self) { group in
                for (index, image) in batch.enumerated() {
                    group.addTask {
                        try await self.uploadImageWithRetry(image: image, index: batchStart + index)
                    }
                }
                
                for try await reference in group {
                    references.append(reference)
                }
            }
        }
        
        return references
    }
    
    // MARK: - Cleanup
    
    func cancelAllUploads() {
        // In a real implementation, this would cancel ongoing upload operations
        isUploading = false
        uploadProgress = 0
    }
}

// MARK: - Photo Library Integration

extension PhotoUploadService {
    
    func requestPhotoLibraryAccess() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch status {
        case .authorized, .limited:
            return true
        case .notDetermined:
            return await PHPhotoLibrary.requestAuthorization(for: .readWrite) == .authorized
        default:
            return false
        }
    }
    
    func loadImageFromAsset(_ asset: PHAsset) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false
            
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: options
            ) { image, info in
                if let error = info?[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: error)
                } else if let image = image {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: PhotoUploadError.assetNotFound)
                }
            }
        }
    }
}
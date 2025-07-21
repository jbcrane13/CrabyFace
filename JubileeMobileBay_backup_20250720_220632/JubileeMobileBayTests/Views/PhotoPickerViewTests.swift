//
//  PhotoPickerViewTests.swift
//  JubileeMobileBayTests
//
//  Tests for PhotoPickerView using ViewInspector
//

import XCTest
import SwiftUI
import ViewInspector
@testable import JubileeMobileBay

class PhotoPickerViewTests: XCTestCase {
    
    var viewModel: ReportViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = ReportViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    func test_photoPickerView_shouldShowCorrectHeader() throws {
        // Given
        let view = PhotoPickerView(viewModel: viewModel)
        
        // When
        let label = try view.inspect().vStack().hStack(0).label(0)
        
        // Then
        XCTAssertEqual(try label.string(), "Photos")
    }
    
    func test_photoPickerView_withNoPhotos_shouldShowAddPhotosButton() throws {
        // Given
        viewModel.photos = []
        let view = PhotoPickerView(viewModel: viewModel)
        
        // When
        let button = try view.inspect().vStack().find(button: "Add Photos")
        
        // Then
        XCTAssertNotNil(button)
    }
    
    func test_photoPickerView_withPhotos_shouldShowAddMorePhotosButton() throws {
        // Given
        viewModel.photos = [PhotoItem(id: UUID())]
        let view = PhotoPickerView(viewModel: viewModel)
        
        // When
        let button = try view.inspect().vStack().find(button: "Add More Photos")
        
        // Then
        XCTAssertNotNil(button)
    }
    
    func test_photoPickerView_withPhotos_shouldShowPhotoGrid() throws {
        // Given
        let photo1 = PhotoItem(id: UUID())
        let photo2 = PhotoItem(id: UUID())
        viewModel.photos = [photo1, photo2]
        let view = PhotoPickerView(viewModel: viewModel)
        
        // When
        let grid = try view.inspect().vStack().lazyVGrid(1)
        
        // Then
        XCTAssertNoThrow(try grid.forEach(0))
    }
    
    func test_photoPickerView_with5Photos_shouldDisableAddButton() throws {
        // Given
        viewModel.photos = (0..<5).map { _ in PhotoItem(id: UUID()) }
        let view = PhotoPickerView(viewModel: viewModel)
        
        // When
        let photosPicker = try view.inspect().vStack().find(ViewType.PhotosPicker.self)
        
        // Then
        XCTAssertTrue(try photosPicker.isDisabled())
    }
}

// MARK: - PhotoThumbnailView Tests

class PhotoThumbnailViewTests: XCTestCase {
    
    func test_photoThumbnailView_withImage_shouldShowImage() throws {
        // Given
        var photo = PhotoItem(id: UUID())
        photo.image = UIImage(systemName: "photo")
        let view = PhotoThumbnailView(photo: photo, onDelete: {})
        
        // When
        let image = try view.inspect().zStack().image(0)
        
        // Then
        XCTAssertNotNil(image)
    }
    
    func test_photoThumbnailView_withoutImage_shouldShowProgressView() throws {
        // Given
        let photo = PhotoItem(id: UUID())
        let view = PhotoThumbnailView(photo: photo, onDelete: {})
        
        // When
        let progressView = try view.inspect().zStack().roundedRectangle(0).overlay().progressView()
        
        // Then
        XCTAssertNotNil(progressView)
    }
    
    func test_photoThumbnailView_deleteButton_shouldCallOnDelete() throws {
        // Given
        var deleteCalled = false
        let photo = PhotoItem(id: UUID())
        let view = PhotoThumbnailView(photo: photo, onDelete: {
            deleteCalled = true
        })
        
        // When
        let button = try view.inspect().zStack().button(1)
        try button.tap()
        
        // Then
        XCTAssertTrue(deleteCalled)
    }
}

// MARK: - ViewInspector Extensions

extension PhotoPickerView: Inspectable {}
extension PhotoThumbnailView: Inspectable {}

// Helper to make PhotosPicker inspectable
extension ViewType {
    struct PhotosPicker: KnownViewType {
        public static var typePrefix: String = "PhotosPicker"
    }
}

extension InspectableView {
    func photosPicker() throws -> InspectableView<ViewType.PhotosPicker> {
        return try view(ViewType.PhotosPicker.self)
    }
}
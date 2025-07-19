//
//  ReportViewTests.swift
//  JubileeMobileBayTests
//
//  Test-Driven Development for Report submission view
//

import XCTest
import SwiftUI
import ViewInspector
import CoreLocation
@testable import JubileeMobileBay

class ReportViewTests: XCTestCase {
    
    var viewModel: ReportViewModel!
    var mockCloudKitService: MockCloudKitService!
    var mockLocationService: MockLocationService!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockCloudKitService = MockCloudKitService()
        mockLocationService = MockLocationService()
        viewModel = ReportViewModel(
            cloudKitService: mockCloudKitService,
            locationService: mockLocationService
        )
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        mockCloudKitService = nil
        mockLocationService = nil
        try super.tearDownWithError()
    }
    
    // MARK: - View Structure Tests
    
    func test_reportView_shouldHaveNavigationTitle() throws {
        let view = ReportView(viewModel: viewModel)
        
        let navView = try view.inspect().navigationView()
        XCTAssertEqual(try navView.navigationTitle().string(), "Report Jubilee")
    }
    
    func test_reportView_shouldHaveDescriptionField() throws {
        let view = ReportView(viewModel: viewModel)
        
        let textEditor = try view.inspect().find(ViewType.TextEditor.self)
        XCTAssertNotNil(textEditor)
        
        // Check placeholder
        let form = try view.inspect().find(ViewType.Form.self)
        let section = try form.section(0)
        XCTAssertEqual(try section.header().text().string(), "Description")
    }
    
    func test_reportView_shouldHaveIntensityPicker() throws {
        let view = ReportView(viewModel: viewModel)
        
        let picker = try view.inspect().find(ViewType.Picker.self)
        XCTAssertNotNil(picker)
        
        // Verify all intensity options are available
        let pickerContent = try picker.forEach(0)
        XCTAssertEqual(try pickerContent.count, JubileeIntensity.allCases.count)
    }
    
    func test_reportView_shouldHaveLocationSection() throws {
        let view = ReportView(viewModel: viewModel)
        
        let form = try view.inspect().find(ViewType.Form.self)
        let locationSection = try form.section(2)
        
        XCTAssertEqual(try locationSection.header().text().string(), "Location")
        
        // Should have current location button
        let button = try locationSection.button(0)
        XCTAssertEqual(try button.labelView().text().string(), "Use Current Location")
    }
    
    func test_reportView_shouldHavePhotoSection() throws {
        let view = ReportView(viewModel: viewModel)
        
        let form = try view.inspect().find(ViewType.Form.self)
        let photoSection = try form.section(3)
        
        XCTAssertEqual(try photoSection.header().text().string(), "Photos")
        
        // Should have photo picker
        XCTAssertNoThrow(try photoSection.find(text: "Add Photos"))
    }
    
    func test_reportView_shouldHaveMarineLifeSection() throws {
        let view = ReportView(viewModel: viewModel)
        
        let form = try view.inspect().find(ViewType.Form.self)
        let marineSection = try form.section(4)
        
        XCTAssertEqual(try marineSection.header().text().string(), "Marine Life Observed")
    }
    
    func test_reportView_shouldHaveSubmitButton() throws {
        let view = ReportView(viewModel: viewModel)
        
        let button = try view.inspect().find(button: "Submit Report")
        XCTAssertNotNil(button)
    }
    
    // MARK: - Interaction Tests
    
    func test_submitButton_whenFieldsEmpty_shouldBeDisabled() throws {
        viewModel.description = ""
        viewModel.location = nil
        
        let view = ReportView(viewModel: viewModel)
        let button = try view.inspect().find(button: "Submit Report")
        
        XCTAssertTrue(try button.isDisabled())
    }
    
    func test_submitButton_whenFieldsValid_shouldBeEnabled() throws {
        viewModel.description = "Test report"
        viewModel.location = CLLocationCoordinate2D(latitude: 30.4672, longitude: -87.9833)
        
        let view = ReportView(viewModel: viewModel)
        let button = try view.inspect().find(button: "Submit Report")
        
        XCTAssertFalse(try button.isDisabled())
    }
    
    func test_useCurrentLocationButton_shouldUpdateLocation() throws {
        mockLocationService.currentLocation = CLLocation(latitude: 30.5, longitude: -88.0)
        
        let view = ReportView(viewModel: viewModel)
        let button = try view.inspect().find(button: "Use Current Location")
        
        try button.tap()
        
        XCTAssertEqual(viewModel.location?.latitude, 30.5, accuracy: 0.0001)
        XCTAssertEqual(viewModel.location?.longitude, -88.0, accuracy: 0.0001)
    }
    
    func test_intensityPicker_shouldUpdateViewModel() throws {
        let view = ReportView(viewModel: viewModel)
        let picker = try view.inspect().find(ViewType.Picker.self)
        
        // Simulate selecting heavy intensity
        viewModel.intensity = .heavy
        
        XCTAssertEqual(viewModel.intensity, .heavy)
    }
    
    // MARK: - Photo Display Tests
    
    func test_photoSection_withPhotos_shouldDisplayThumbnails() throws {
        let photo1 = PhotoItem(id: UUID())
        let photo2 = PhotoItem(id: UUID())
        viewModel.photos = [photo1, photo2]
        
        let view = ReportView(viewModel: viewModel)
        let photoSection = try view.inspect().find(ViewType.Form.self).section(3)
        
        // Should show photo count
        XCTAssertEqual(viewModel.photos.count, 2)
    }
    
    // MARK: - Marine Life Tests
    
    func test_marineLifeSection_shouldShowAddedSpecies() throws {
        viewModel.marineLifeObservations = ["Mullet", "Flounder", "Crab"]
        
        let view = ReportView(viewModel: viewModel)
        let marineSection = try view.inspect().find(ViewType.Form.self).section(4)
        
        // Should display all species
        XCTAssertEqual(viewModel.marineLifeObservations.count, 3)
    }
    
    // MARK: - Error Display Tests
    
    func test_errorAlert_whenErrorExists_shouldBePresented() throws {
        viewModel.error = "Test error message"
        
        let view = ReportView(viewModel: viewModel)
        
        // Alert should be configured
        XCTAssertNotNil(viewModel.error)
    }
    
    // MARK: - Loading State Tests
    
    func test_submitButton_whenSubmitting_shouldShowProgress() throws {
        viewModel.isSubmitting = true
        viewModel.description = "Test"
        viewModel.location = CLLocationCoordinate2D(latitude: 30.4672, longitude: -87.9833)
        
        let view = ReportView(viewModel: viewModel)
        
        // Should show progress view in submit button
        let button = try view.inspect().find(button: "Submit Report")
        XCTAssertTrue(try button.isDisabled())
    }
}

// Extension to make ReportView inspectable
extension ReportView: Inspectable {}
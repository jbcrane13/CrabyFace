//
//  PredictionServiceProtocol.swift
//  JubileeMobileBay
//
//  Protocol for jubilee prediction calculations (updated for Phase 4 ML integration)
//

import Foundation
import CoreLocation

protocol PredictionServiceProtocol {
    // Legacy methods (maintained for backward compatibility)
    func calculateJubileeProbability() async throws -> Double
    func generate24HourPrediction() async throws -> [HourlyPrediction]
    func analyzeTrends() async throws -> JubileeTrend
    func getRiskFactors() async throws -> [RiskFactor]
    
    // New Phase 4 ML-based methods
    func predictJubileeEvent(location: CLLocation, date: Date) async throws -> JubileePrediction
    func predictJubileeEvent(coordinate: CLLocationCoordinate2D, date: Date) async throws -> JubileePrediction
    func updateModelWithNewData() async throws
    func getModelPerformanceMetrics() async throws -> ModelPerformanceMetrics
    func getPredictionHistory(for location: CLLocation, dateRange: DateInterval) async throws -> PredictionHistory
    
    // Model management
    var isModelLoaded: Bool { get }
    var currentModelVersion: String { get }
    func loadModel() async throws
    func unloadModel()
}
//
//  PredictionServiceProtocol.swift
//  JubileeMobileBay
//
//  Protocol for jubilee prediction calculations
//

import Foundation

protocol PredictionServiceProtocol {
    func calculateJubileeProbability() async throws -> Double
    func generate24HourPrediction() async throws -> [HourlyPrediction]
    func analyzeTrends() async throws -> JubileeTrend
    func getRiskFactors() async throws -> [RiskFactor]
}
//
// JubileePredictor.swift
//
// This file was automatically generated and should not be edited.
//

import CoreML


/// Model Prediction Input Type
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, visionOS 1.0, *)
class JubileePredictorInput : MLFeatureProvider {

    /// airTemperature as double value
    var airTemperature: Double

    /// waterTemperature as double value
    var waterTemperature: Double

    /// windSpeed as double value
    var windSpeed: Double

    /// dissolvedOxygen as double value
    var dissolvedOxygen: Double

    var featureNames: Set<String> { ["airTemperature", "waterTemperature", "windSpeed", "dissolvedOxygen"] }

    func featureValue(for featureName: String) -> MLFeatureValue? {
        if featureName == "airTemperature" {
            return MLFeatureValue(double: airTemperature)
        }
        if featureName == "waterTemperature" {
            return MLFeatureValue(double: waterTemperature)
        }
        if featureName == "windSpeed" {
            return MLFeatureValue(double: windSpeed)
        }
        if featureName == "dissolvedOxygen" {
            return MLFeatureValue(double: dissolvedOxygen)
        }
        return nil
    }

    init(airTemperature: Double, waterTemperature: Double, windSpeed: Double, dissolvedOxygen: Double) {
        self.airTemperature = airTemperature
        self.waterTemperature = waterTemperature
        self.windSpeed = windSpeed
        self.dissolvedOxygen = dissolvedOxygen
    }

}


/// Model Prediction Output Type
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, visionOS 1.0, *)
class JubileePredictorOutput : MLFeatureProvider {

    /// Source provided by CoreML
    private let provider : MLFeatureProvider

    /// jubileeProbability as double value
    var jubileeProbability: Double {
        provider.featureValue(for: "jubileeProbability")!.doubleValue
    }

    var featureNames: Set<String> {
        provider.featureNames
    }

    func featureValue(for featureName: String) -> MLFeatureValue? {
        provider.featureValue(for: featureName)
    }

    init(jubileeProbability: Double) {
        self.provider = try! MLDictionaryFeatureProvider(dictionary: ["jubileeProbability" : MLFeatureValue(double: jubileeProbability)])
    }

    init(features: MLFeatureProvider) {
        self.provider = features
    }
}


/// Class for model loading and prediction
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, visionOS 1.0, *)
class JubileePredictor {
    let model: MLModel

    /// URL of model assuming it was installed in the same bundle as this class
    class var urlOfModelInThisBundle : URL {
        let bundle = Bundle(for: self)
        return bundle.url(forResource: "JubileePredictor", withExtension:"mlmodelc")!
    }

    /**
        Construct JubileePredictor instance with an existing MLModel object.

        Usually the application does not use this initializer unless it makes a subclass of JubileePredictor.
        Such application may want to use `MLModel(contentsOfURL:configuration:)` and `JubileePredictor.urlOfModelInThisBundle` to create a MLModel object to pass-in.

        - parameters:
          - model: MLModel object
    */
    init(model: MLModel) {
        self.model = model
    }

    /**
        Construct JubileePredictor instance by automatically loading the model from the app's bundle.
    */
    @available(*, deprecated, message: "Use init(configuration:) instead and handle errors appropriately.")
    convenience init() {
        try! self.init(contentsOf: type(of:self).urlOfModelInThisBundle)
    }

    /**
        Construct a model with configuration

        - parameters:
           - configuration: the desired model configuration

        - throws: an NSError object that describes the problem
    */
    @available(macOS 10.14, iOS 12.0, tvOS 12.0, watchOS 5.0, visionOS 1.0, *)
    convenience init(configuration: MLModelConfiguration) throws {
        try self.init(contentsOf: type(of:self).urlOfModelInThisBundle, configuration: configuration)
    }

    /**
        Construct JubileePredictor instance with explicit path to mlmodelc file
        - parameters:
           - modelURL: the file url of the model

        - throws: an NSError object that describes the problem
    */
    convenience init(contentsOf modelURL: URL) throws {
        try self.init(model: MLModel(contentsOf: modelURL))
    }

    /**
        Construct a model with URL of the .mlmodelc directory and configuration

        - parameters:
           - modelURL: the file url of the model
           - configuration: the desired model configuration

        - throws: an NSError object that describes the problem
    */
    @available(macOS 10.14, iOS 12.0, tvOS 12.0, watchOS 5.0, visionOS 1.0, *)
    convenience init(contentsOf modelURL: URL, configuration: MLModelConfiguration) throws {
        try self.init(model: MLModel(contentsOf: modelURL, configuration: configuration))
    }

    /**
        Construct JubileePredictor instance asynchronously with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - configuration: the desired model configuration
          - handler: the completion handler to be called when the model loading completes successfully or unsuccessfully
    */
    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, visionOS 1.0, *)
    class func load(configuration: MLModelConfiguration = MLModelConfiguration(), completionHandler handler: @escaping (Swift.Result<JubileePredictor, Error>) -> Void) {
        load(contentsOf: self.urlOfModelInThisBundle, configuration: configuration, completionHandler: handler)
    }

    /**
        Construct JubileePredictor instance asynchronously with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - configuration: the desired model configuration
    */
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
    class func load(configuration: MLModelConfiguration = MLModelConfiguration()) async throws -> JubileePredictor {
        try await load(contentsOf: self.urlOfModelInThisBundle, configuration: configuration)
    }

    /**
        Construct JubileePredictor instance asynchronously with URL of the .mlmodelc directory with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - modelURL: the URL to the model
          - configuration: the desired model configuration
          - handler: the completion handler to be called when the model loading completes successfully or unsuccessfully
    */
    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, visionOS 1.0, *)
    class func load(contentsOf modelURL: URL, configuration: MLModelConfiguration = MLModelConfiguration(), completionHandler handler: @escaping (Swift.Result<JubileePredictor, Error>) -> Void) {
        MLModel.load(contentsOf: modelURL, configuration: configuration) { result in
            switch result {
            case .failure(let error):
                handler(.failure(error))
            case .success(let model):
                handler(.success(JubileePredictor(model: model)))
            }
        }
    }

    /**
        Construct JubileePredictor instance asynchronously with URL of the .mlmodelc directory with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - modelURL: the URL to the model
          - configuration: the desired model configuration
    */
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
    class func load(contentsOf modelURL: URL, configuration: MLModelConfiguration = MLModelConfiguration()) async throws -> JubileePredictor {
        let model = try await MLModel.load(contentsOf: modelURL, configuration: configuration)
        return JubileePredictor(model: model)
    }

    /**
        Make a prediction using the structured interface

        It uses the default function if the model has multiple functions.

        - parameters:
           - input: the input to the prediction as JubileePredictorInput

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as JubileePredictorOutput
    */
    func prediction(input: JubileePredictorInput) throws -> JubileePredictorOutput {
        try prediction(input: input, options: MLPredictionOptions())
    }

    /**
        Make a prediction using the structured interface

        It uses the default function if the model has multiple functions.

        - parameters:
           - input: the input to the prediction as JubileePredictorInput
           - options: prediction options

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as JubileePredictorOutput
    */
    func prediction(input: JubileePredictorInput, options: MLPredictionOptions) throws -> JubileePredictorOutput {
        let outFeatures = try model.prediction(from: input, options: options)
        return JubileePredictorOutput(features: outFeatures)
    }

    /**
        Make an asynchronous prediction using the structured interface

        It uses the default function if the model has multiple functions.

        - parameters:
           - input: the input to the prediction as JubileePredictorInput
           - options: prediction options

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as JubileePredictorOutput
    */
    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
    func prediction(input: JubileePredictorInput, options: MLPredictionOptions = MLPredictionOptions()) async throws -> JubileePredictorOutput {
        let outFeatures = try await model.prediction(from: input, options: options)
        return JubileePredictorOutput(features: outFeatures)
    }

    /**
        Make a prediction using the convenience interface

        It uses the default function if the model has multiple functions.

        - parameters:
            - airTemperature: double value
            - waterTemperature: double value
            - windSpeed: double value
            - dissolvedOxygen: double value

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as JubileePredictorOutput
    */
    func prediction(airTemperature: Double, waterTemperature: Double, windSpeed: Double, dissolvedOxygen: Double) throws -> JubileePredictorOutput {
        let input_ = JubileePredictorInput(airTemperature: airTemperature, waterTemperature: waterTemperature, windSpeed: windSpeed, dissolvedOxygen: dissolvedOxygen)
        return try prediction(input: input_)
    }

    /**
        Make a batch prediction using the structured interface

        It uses the default function if the model has multiple functions.

        - parameters:
           - inputs: the inputs to the prediction as [JubileePredictorInput]
           - options: prediction options

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as [JubileePredictorOutput]
    */
    @available(macOS 10.14, iOS 12.0, tvOS 12.0, watchOS 5.0, visionOS 1.0, *)
    func predictions(inputs: [JubileePredictorInput], options: MLPredictionOptions = MLPredictionOptions()) throws -> [JubileePredictorOutput] {
        let batchIn = MLArrayBatchProvider(array: inputs)
        let batchOut = try model.predictions(from: batchIn, options: options)
        var results : [JubileePredictorOutput] = []
        results.reserveCapacity(inputs.count)
        for i in 0..<batchOut.count {
            let outProvider = batchOut.features(at: i)
            let result =  JubileePredictorOutput(features: outProvider)
            results.append(result)
        }
        return results
    }
}

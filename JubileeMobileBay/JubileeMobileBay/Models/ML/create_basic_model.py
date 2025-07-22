#!/usr/bin/env python3
"""
Create a basic Core ML model for JubileeMobileBay
This creates a simple model that outputs jubilee probability
"""

import coremltools as ct
import numpy as np
from sklearn.ensemble import RandomForestRegressor

def create_basic_model():
    """Create a basic Random Forest model for jubilee prediction"""
    
    # Generate synthetic training data
    np.random.seed(42)
    n_samples = 1000
    
    # Features: airTemp, waterTemp, windSpeed, dissolvedOxygen
    X = np.random.rand(n_samples, 4)
    
    # Scale features to realistic ranges
    X[:, 0] = X[:, 0] * 30 + 65  # Air temp: 65-95°F
    X[:, 1] = X[:, 1] * 18 + 70  # Water temp: 70-88°F
    X[:, 2] = X[:, 2] * 25       # Wind speed: 0-25 mph
    X[:, 3] = X[:, 3] * 6 + 2    # Dissolved oxygen: 2-8 mg/L
    
    # Create synthetic outputs based on simple logic
    probability = np.zeros(n_samples)
    
    for i in range(n_samples):
        # Calculate probability based on conditions
        prob = 0.1  # Base probability
        
        # Temperature factors
        if 75 <= X[i, 0] <= 85:  # Optimal air temp
            prob += 0.2
        if 78 <= X[i, 1] <= 85:  # Optimal water temp
            prob += 0.25
            
        # Wind factor (low wind is better)
        if X[i, 2] < 5:
            prob += 0.3
        elif X[i, 2] > 15:
            prob -= 0.2
            
        # DO factor (low DO is indicator)
        if X[i, 3] < 4:
            prob += 0.25
        elif X[i, 3] > 6:
            prob -= 0.15
            
        probability[i] = np.clip(prob + np.random.uniform(-0.05, 0.05), 0.0, 1.0)
    
    # Train a simple model
    model = RandomForestRegressor(n_estimators=20, max_depth=5, random_state=42)
    model.fit(X, probability)
    
    # Convert to Core ML - single output version
    coreml_model = ct.converters.sklearn.convert(
        model,
        input_features=[
            ('airTemperature', ct.models.datatypes.Double()),
            ('waterTemperature', ct.models.datatypes.Double()),
            ('windSpeed', ct.models.datatypes.Double()),
            ('dissolvedOxygen', ct.models.datatypes.Double())
        ],
        output_feature_names='prediction'
    )
    
    # Update the spec to have the correct output names
    spec = coreml_model._spec
    
    # Change the output name from 'prediction' to 'jubileeProbability'
    spec.description.output[0].name = 'jubileeProbability'
    spec.description.output[0].shortDescription = 'Probability of jubilee event (0.0-1.0)'
    
    # Update the neural network output as well
    if spec.HasField('treeEnsembleRegressor'):
        spec.treeEnsembleRegressor.doubleOutput.MergeFrom(
            spec.treeEnsembleRegressor.floatOutput
        )
        spec.treeEnsembleRegressor.ClearField('floatOutput')
    
    # Add a second output for confidence score (fixed value for now)
    # We'll add a simple post-processing layer
    from coremltools.proto import Model_pb2
    
    # Create a new output
    new_output = spec.description.output.add()
    new_output.name = 'confidenceScore'
    new_output.shortDescription = 'Model confidence score (0.0-1.0)'
    new_output.type.doubleType.MergeFrom(Model_pb2.FeatureType.DoubleFeatureType())
    
    # Set metadata
    spec.description.metadata.author = 'JubileeMobileBay Team'
    spec.description.metadata.shortDescription = 'Placeholder model for jubilee event prediction'
    spec.description.metadata.versionString = '1.0.0'
    spec.description.metadata.license = 'MIT'
    
    # Update input descriptions
    spec.description.input[0].shortDescription = 'Air temperature in Fahrenheit'
    spec.description.input[1].shortDescription = 'Water temperature in Fahrenheit'
    spec.description.input[2].shortDescription = 'Wind speed in miles per hour'
    spec.description.input[3].shortDescription = 'Dissolved oxygen in mg/L'
    
    # Create the final model
    final_model = ct.models.MLModel(spec)
    
    # Since we can't easily add a second output to RandomForest, we'll create a wrapper
    # that adds a fixed confidence score
    
    return final_model

def create_wrapper_model():
    """Create a wrapper that adds confidence score"""
    # For now, let's just create a model with single output
    # The app can calculate confidence separately
    return create_basic_model()

if __name__ == "__main__":
    print("Creating placeholder Core ML model...")
    
    try:
        # Create the model
        model = create_wrapper_model()
        
        # Save the model
        output_path = 'JubileePredictor.mlmodel'
        model.save(output_path)
        print(f"✅ Model saved to: {output_path}")
        
        # Test the model
        print("\nTesting the model...")
        test_cases = [
            {
                'name': 'Optimal conditions',
                'input': {
                    'airTemperature': 80.0,
                    'waterTemperature': 82.0,
                    'windSpeed': 3.0,
                    'dissolvedOxygen': 3.5
                }
            },
            {
                'name': 'Poor conditions',
                'input': {
                    'airTemperature': 65.0,
                    'waterTemperature': 70.0,
                    'windSpeed': 20.0,
                    'dissolvedOxygen': 7.0
                }
            },
            {
                'name': 'Average conditions',
                'input': {
                    'airTemperature': 75.0,
                    'waterTemperature': 78.0,
                    'windSpeed': 10.0,
                    'dissolvedOxygen': 5.0
                }
            }
        ]
        
        for test in test_cases:
            prediction = model.predict(test['input'])
            print(f"\n{test['name']}:")
            print(f"  Input: {test['input']}")
            print(f"  Jubilee Probability: {float(prediction['jubileeProbability']):.3f}")
            # Note: confidence score will be calculated in the app
            
        print("\n✅ Model created successfully!")
        print("\nNOTE: This is a placeholder model with basic logic.")
        print("The model currently outputs only jubileeProbability.")
        print("The app will need to calculate confidenceScore separately.")
        print("\nTo use in Xcode:")
        print("1. Add JubileePredictor.mlmodel to your Xcode project")
        print("2. Ensure target membership is set to JubileeMobileBay")
        print("3. Xcode will auto-generate the JubileePredictor class")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
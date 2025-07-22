#!/usr/bin/env python3
"""
Create a simple placeholder Core ML model for JubileeMobileBay
This creates a basic model that can be replaced with a real trained model later
"""

import coremltools as ct
import numpy as np
from sklearn.ensemble import RandomForestRegressor
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler

def create_simple_model():
    """Create a simple Random Forest model for jubilee prediction"""
    
    # Generate some synthetic training data
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
    # Probability increases with warm temps and low wind/DO
    probability = np.zeros(n_samples)
    confidence = np.zeros(n_samples)
    
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
            
        probability[i] = np.clip(prob, 0.0, 1.0)
        
        # Confidence based on how extreme the conditions are
        conf = 0.5
        if prob > 0.7 or prob < 0.2:
            conf = 0.8
        elif 0.4 <= prob <= 0.6:
            conf = 0.6
            
        confidence[i] = conf + np.random.uniform(-0.1, 0.1)
        confidence[i] = np.clip(confidence[i], 0.3, 0.95)
    
    # We'll train two separate models (one for each output) since CoreML doesn't support MultiOutputRegressor
    # Train probability model
    prob_model = RandomForestRegressor(n_estimators=10, max_depth=5, random_state=42)
    prob_model.fit(X, probability)
    
    # Train confidence model
    conf_model = RandomForestRegressor(n_estimators=10, max_depth=5, random_state=42)
    conf_model.fit(X, confidence)
    
    # Convert probability model to Core ML
    prob_coreml = ct.converters.sklearn.convert(
        prob_model,
        input_features=[
            ('airTemperature', ct.models.datatypes.Double()),
            ('waterTemperature', ct.models.datatypes.Double()),
            ('windSpeed', ct.models.datatypes.Double()),
            ('dissolvedOxygen', ct.models.datatypes.Double())
        ],
        output_feature_names=['jubileeProbability']
    )
    
    # Convert confidence model to Core ML
    conf_coreml = ct.converters.sklearn.convert(
        conf_model,
        input_features=[
            ('airTemperature', ct.models.datatypes.Double()),
            ('waterTemperature', ct.models.datatypes.Double()),
            ('windSpeed', ct.models.datatypes.Double()),
            ('dissolvedOxygen', ct.models.datatypes.Double())
        ],
        output_feature_names=['confidenceScore']
    )
    
    # Create a pipeline model that combines both outputs
    # Load the specs
    prob_spec = prob_coreml._spec
    conf_spec = conf_coreml._spec
    
    # Create a new pipeline model
    from coremltools.models import MLModel
    from coremltools.models.pipeline import Pipeline
    from coremltools.models.datatypes import Double
    
    # Create pipeline
    pipeline = Pipeline(
        input_features=[
            ('airTemperature', Double()),
            ('waterTemperature', Double()),
            ('windSpeed', Double()),
            ('dissolvedOxygen', Double())
        ],
        output_features=[
            ('jubileeProbability', Double()),
            ('confidenceScore', Double())
        ]
    )
    
    # Add both models to pipeline
    pipeline.add_model(prob_coreml)
    pipeline.add_model(conf_coreml)
    
    # Create the final model
    pipeline_model = MLModel(pipeline.spec)
    
    # Set metadata
    pipeline_model.author = 'JubileeMobileBay Team'
    pipeline_model.short_description = 'Placeholder model for jubilee event prediction'
    pipeline_model.version = '1.0.0'
    pipeline_model.license = 'MIT'
    
    # Update output descriptions
    spec = pipeline_model._spec
    spec.description.output[0].shortDescription = 'Probability of jubilee event (0.0-1.0)'
    spec.description.output[1].shortDescription = 'Model confidence score (0.0-1.0)'
    
    # Update input descriptions
    spec.description.input[0].shortDescription = 'Air temperature in Fahrenheit'
    spec.description.input[1].shortDescription = 'Water temperature in Fahrenheit'
    spec.description.input[2].shortDescription = 'Wind speed in miles per hour'
    spec.description.input[3].shortDescription = 'Dissolved oxygen in mg/L'
    
    # Create updated model
    final_model = MLModel(spec)
    
    return final_model

if __name__ == "__main__":
    print("Creating placeholder Core ML model...")
    
    try:
        # Create the model
        model = create_simple_model()
        
        # Save the model
        output_path = 'JubileePredictor.mlmodel'
        model.save(output_path)
        print(f"Model saved to: {output_path}")
        
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
            print(f"  Confidence Score: {float(prediction['confidenceScore']):.3f}")
            
    except Exception as e:
        print(f"Error: {e}")
        print("\nTrying alternative approach...")
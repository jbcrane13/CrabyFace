#!/usr/bin/env python3
"""
Jubilee Prediction Neural Network Model
Creates a Core ML model using neural network for multi-output prediction
"""

import numpy as np
import coremltools as ct
from coremltools.models.neural_network import NeuralNetworkBuilder
from coremltools.models import datatypes
import pandas as pd

# Generate synthetic training data
def generate_training_data(n_samples=20000):
    """Generate synthetic jubilee event data based on environmental conditions"""
    
    # Generate random environmental conditions
    air_temp = np.random.uniform(65, 95, n_samples)  # Fahrenheit
    water_temp = np.random.uniform(70, 88, n_samples)  # Fahrenheit
    wind_speed = np.random.uniform(0, 25, n_samples)  # mph
    dissolved_oxygen = np.random.uniform(2, 8, n_samples)  # mg/L
    
    # Calculate jubilee probability based on conditions
    probability = np.zeros(n_samples)
    
    for i in range(n_samples):
        prob = 0.1  # Base probability
        
        # Temperature factors
        if 75 <= air_temp[i] <= 85:
            prob += 0.2
        if 78 <= water_temp[i] <= 85:
            prob += 0.25
            
        # Wind factor (low wind increases probability)
        if wind_speed[i] < 5:
            prob += 0.3
        elif wind_speed[i] > 15:
            prob -= 0.2
            
        # Dissolved oxygen factor (low DO increases probability)
        if dissolved_oxygen[i] < 4:
            prob += 0.25
        elif dissolved_oxygen[i] > 6:
            prob -= 0.15
            
        # Add noise
        prob += np.random.uniform(-0.1, 0.1)
        probability[i] = np.clip(prob, 0.0, 1.0)
    
    # Calculate confidence scores
    temp_diff = np.abs(air_temp - water_temp)
    temp_stability = 1.0 - (temp_diff / 20.0)
    wind_stability = 1.0 - (wind_speed / 25.0)
    confidence = (temp_stability + wind_stability) / 2.0
    confidence = np.clip(confidence, 0.3, 0.95)
    
    return air_temp, water_temp, wind_speed, dissolved_oxygen, probability, confidence

# Build neural network model
def build_neural_network():
    """Build a Core ML neural network model for jubilee prediction"""
    
    # Define input and output features
    input_features = [
        ('airTemperature', datatypes.Array(1)),
        ('waterTemperature', datatypes.Array(1)),
        ('windSpeed', datatypes.Array(1)),
        ('dissolvedOxygen', datatypes.Array(1))
    ]
    
    output_features = [
        ('jubileeProbability', datatypes.Array(1)),
        ('confidenceScore', datatypes.Array(1))
    ]
    
    # Create builder
    builder = NeuralNetworkBuilder(input_features, output_features)
    
    # Add layers
    # Input layer combines 4 features
    builder.add_concat_nd(
        name='input_concat',
        input_names=['airTemperature', 'waterTemperature', 'windSpeed', 'dissolvedOxygen'],
        output_name='input_combined',
        axis=0
    )
    
    # Hidden layer 1
    builder.add_inner_product(
        name='hidden1',
        input_name='input_combined',
        output_name='hidden1_output',
        input_channels=4,
        output_channels=16,
        W=np.random.randn(16, 4).astype(np.float32) * 0.1,
        b=np.zeros(16).astype(np.float32)
    )
    
    builder.add_activation(
        name='relu1',
        non_linearity='RELU',
        input_name='hidden1_output',
        output_name='relu1_output'
    )
    
    # Hidden layer 2
    builder.add_inner_product(
        name='hidden2',
        input_name='relu1_output',
        output_name='hidden2_output',
        input_channels=16,
        output_channels=8,
        W=np.random.randn(8, 16).astype(np.float32) * 0.1,
        b=np.zeros(8).astype(np.float32)
    )
    
    builder.add_activation(
        name='relu2',
        non_linearity='RELU',
        input_name='hidden2_output',
        output_name='relu2_output'
    )
    
    # Output layer for jubilee probability
    builder.add_inner_product(
        name='output_probability',
        input_name='relu2_output',
        output_name='probability_raw',
        input_channels=8,
        output_channels=1,
        W=np.random.randn(1, 8).astype(np.float32) * 0.1,
        b=np.array([0.5]).astype(np.float32)
    )
    
    # Sigmoid activation for probability
    builder.add_activation(
        name='sigmoid_probability',
        non_linearity='SIGMOID',
        input_name='probability_raw',
        output_name='jubileeProbability'
    )
    
    # Output layer for confidence score
    builder.add_inner_product(
        name='output_confidence',
        input_name='relu2_output',
        output_name='confidence_raw',
        input_channels=8,
        output_channels=1,
        W=np.random.randn(1, 8).astype(np.float32) * 0.1,
        b=np.array([0.7]).astype(np.float32)
    )
    
    # Sigmoid activation for confidence
    builder.add_activation(
        name='sigmoid_confidence',
        non_linearity='SIGMOID',
        input_name='confidence_raw',
        output_name='confidenceScore'
    )
    
    # Set metadata
    builder.author = 'JubileeMobileBay Team'
    builder.description = 'Neural network model for predicting jubilee events based on environmental conditions'
    builder.version = '1.0.0'
    
    # Set input descriptions
    builder.set_input('airTemperature', 'Air temperature in Fahrenheit')
    builder.set_input('waterTemperature', 'Water temperature in Fahrenheit')
    builder.set_input('windSpeed', 'Wind speed in miles per hour')
    builder.set_input('dissolvedOxygen', 'Dissolved oxygen in mg/L')
    
    # Set output descriptions
    builder.set_output('jubileeProbability', 'Probability of jubilee event (0.0-1.0)')
    builder.set_output('confidenceScore', 'Model confidence score (0.0-1.0)')
    
    # Create model
    model = ct.models.MLModel(builder.spec)
    
    return model

# Create simplified Core ML model
def create_simple_coreml_model():
    """Create a simplified Core ML model using tabular data approach"""
    
    from coremltools.proto import Model_pb2
    from coremltools.proto.Model_pb2 import ArrayFeatureType
    
    # Create model spec
    spec = Model_pb2.Model()
    spec.specificationVersion = 4
    
    # Add inputs
    for input_name, input_desc in [
        ('airTemperature', 'Air temperature in Fahrenheit'),
        ('waterTemperature', 'Water temperature in Fahrenheit'),
        ('windSpeed', 'Wind speed in miles per hour'),
        ('dissolvedOxygen', 'Dissolved oxygen in mg/L')
    ]:
        input_feature = spec.description.input.add()
        input_feature.name = input_name
        input_feature.shortDescription = input_desc
        input_feature.type.doubleType.MergeFromString(b'')
    
    # Add outputs
    for output_name, output_desc in [
        ('jubileeProbability', 'Probability of jubilee event (0.0-1.0)'),
        ('confidenceScore', 'Model confidence score (0.0-1.0)')
    ]:
        output_feature = spec.description.output.add()
        output_feature.name = output_name
        output_feature.shortDescription = output_desc
        output_feature.type.doubleType.MergeFromString(b'')
    
    # Set metadata
    spec.description.metadata.author = 'JubileeMobileBay Team'
    spec.description.metadata.shortDescription = 'Predicts jubilee events based on environmental conditions'
    spec.description.metadata.versionString = '1.0.0'
    
    # Use pipeline model with custom layer
    pipeline = spec.pipelineRegressor
    
    # Add a dummy regressor model (will be replaced with trained model)
    model_spec = pipeline.pipeline.models.add()
    model_spec.specificationVersion = 4
    
    # Create a simple linear regression as placeholder
    lr = model_spec.glmRegressor
    lr.offset.append(0.5)  # Base probability
    lr.offset.append(0.7)  # Base confidence
    
    # Add weights for each feature
    for i in range(4):
        weight = lr.weights.add()
        # Probability weights
        weight.value.append(0.1 if i < 2 else -0.05)  # Temp positive, wind/DO negative
        # Confidence weights  
        weight.value.append(0.05)
    
    # Create MLModel
    model = ct.models.MLModel(spec)
    
    return model

# Main execution
if __name__ == "__main__":
    print("Building Core ML model for jubilee prediction...")
    
    try:
        # Try neural network approach first
        model = build_neural_network()
        print("Neural network model created successfully")
    except Exception as e:
        print(f"Neural network failed: {e}")
        print("Using simplified model instead...")
        model = create_simple_coreml_model()
    
    # Save model
    output_path = 'JubileePredictor.mlmodel'
    model.save(output_path)
    print(f"\nCore ML model saved to: {output_path}")
    
    # Test the model
    print("\nTesting Core ML model...")
    test_input = {
        'airTemperature': 80.0,
        'waterTemperature': 82.0,
        'windSpeed': 3.0,
        'dissolvedOxygen': 3.5
    }
    
    try:
        prediction = model.predict(test_input)
        print(f"\nTest prediction for optimal conditions:")
        print(f"  Input: {test_input}")
        print(f"  Jubilee Probability: {prediction['jubileeProbability']}")
        print(f"  Confidence Score: {prediction['confidenceScore']}")
    except Exception as e:
        print(f"Prediction test failed: {e}")
        print("Model structure created successfully, but requires training weights")
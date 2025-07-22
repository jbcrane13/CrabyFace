#!/usr/bin/env python3
"""
Create a placeholder Core ML model for JubileeMobileBay
This creates a simple model that can be replaced with a real trained model later
"""

import coremltools as ct
from coremltools.models.neural_network import NeuralNetworkBuilder
import numpy as np

def create_placeholder_model():
    """Create a simple neural network model for jubilee prediction"""
    
    # Define input and output features
    input_features = [
        ('airTemperature', ct.models.datatypes.Double(), 'Air temperature in Fahrenheit'),
        ('waterTemperature', ct.models.datatypes.Double(), 'Water temperature in Fahrenheit'),
        ('windSpeed', ct.models.datatypes.Double(), 'Wind speed in miles per hour'),
        ('dissolvedOxygen', ct.models.datatypes.Double(), 'Dissolved oxygen in mg/L')
    ]
    
    output_features = [
        ('jubileeProbability', ct.models.datatypes.Double(), 'Probability of jubilee event (0.0-1.0)'),
        ('confidenceScore', ct.models.datatypes.Double(), 'Model confidence score (0.0-1.0)')
    ]
    
    # Create a neural network builder
    builder = NeuralNetworkBuilder(
        input_features=input_features,
        output_features=output_features,
        disable_rank5_shape_mapping=True
    )
    
    # Add a simple neural network that simulates jubilee prediction logic
    # Input layer -> Hidden layer (8 units) -> Output layer (2 units)
    
    # Hidden layer weights (4 inputs x 8 hidden units)
    hidden_weights = np.array([
        [0.2, -0.1, 0.3, -0.2, 0.1, -0.3, 0.2, -0.1],  # airTemp
        [0.3, -0.2, 0.1, -0.3, 0.2, -0.1, 0.3, -0.2],  # waterTemp
        [-0.4, 0.3, -0.2, 0.1, -0.3, 0.2, -0.1, 0.4],  # windSpeed (negative correlation)
        [-0.3, 0.2, -0.4, 0.3, -0.1, 0.4, -0.2, 0.1],  # dissolvedOxygen (negative correlation)
    ])
    
    # Hidden layer bias
    hidden_bias = np.array([0.1, -0.1, 0.1, -0.1, 0.1, -0.1, 0.1, -0.1])
    
    # Output layer weights (8 hidden x 2 outputs)
    output_weights = np.array([
        [0.4, 0.3],   # Hidden unit 1 -> [probability, confidence]
        [-0.3, 0.2],  # Hidden unit 2
        [0.2, 0.4],   # Hidden unit 3
        [-0.2, 0.3],  # Hidden unit 4
        [0.3, 0.2],   # Hidden unit 5
        [-0.1, 0.4],  # Hidden unit 6
        [0.2, 0.3],   # Hidden unit 7
        [-0.2, 0.2],  # Hidden unit 8
    ])
    
    # Output layer bias
    output_bias = np.array([0.1, 0.5])  # Base probability and confidence
    
    # Add layers to the model
    # First, we need to normalize inputs (assuming reasonable ranges)
    # Air temp: 65-95°F -> normalized to [-1, 1]
    # Water temp: 70-88°F -> normalized to [-1, 1]
    # Wind speed: 0-25 mph -> normalized to [-1, 1]
    # Dissolved oxygen: 2-8 mg/L -> normalized to [-1, 1]
    
    # Add normalization layers for each input
    builder.add_elementwise(
        name='normalize_airTemp',
        input_names=['airTemperature'],
        output_name='norm_airTemp',
        mode='LINEAR',
        alpha=(2.0 / 30.0),  # scale factor
        beta=-80.0 * (2.0 / 30.0)  # offset to center at 80°F
    )
    
    builder.add_elementwise(
        name='normalize_waterTemp',
        input_names=['waterTemperature'],
        output_name='norm_waterTemp',
        mode='LINEAR',
        alpha=(2.0 / 18.0),  # scale factor
        beta=-79.0 * (2.0 / 18.0)  # offset to center at 79°F
    )
    
    builder.add_elementwise(
        name='normalize_windSpeed',
        input_names=['windSpeed'],
        output_name='norm_windSpeed',
        mode='LINEAR',
        alpha=(2.0 / 25.0),  # scale factor
        beta=-12.5 * (2.0 / 25.0)  # offset to center at 12.5 mph
    )
    
    builder.add_elementwise(
        name='normalize_dissolvedOxygen',
        input_names=['dissolvedOxygen'],
        output_name='norm_dissolvedOxygen',
        mode='LINEAR',
        alpha=(2.0 / 6.0),  # scale factor
        beta=-5.0 * (2.0 / 6.0)  # offset to center at 5 mg/L
    )
    
    # Add hidden layer
    builder.add_inner_product(
        name='hidden_layer',
        W=hidden_weights.T.flatten(),
        b=hidden_bias,
        input_channels=4,
        output_channels=8,
        has_bias=True,
        input_name=['norm_airTemp', 'norm_waterTemp', 'norm_windSpeed', 'norm_dissolvedOxygen'],
        output_name='hidden_activation'
    )
    
    # Add ReLU activation
    builder.add_activation(
        name='hidden_relu',
        non_linearity='RELU',
        input_name='hidden_activation',
        output_name='hidden_relu_output'
    )
    
    # Add output layer
    builder.add_inner_product(
        name='output_layer',
        W=output_weights.T.flatten(),
        b=output_bias,
        input_channels=8,
        output_channels=2,
        has_bias=True,
        input_name='hidden_relu_output',
        output_name='raw_output'
    )
    
    # Add sigmoid activation to ensure outputs are in [0, 1] range
    builder.add_activation(
        name='output_sigmoid',
        non_linearity='SIGMOID',
        input_name='raw_output',
        output_name='sigmoid_output'
    )
    
    # Split the output into two separate outputs
    # First output: jubileeProbability
    builder.add_slice(
        name='extract_probability',
        input_name='sigmoid_output',
        output_name='jubileeProbability',
        axis='C',
        start_index=0,
        end_index=1
    )
    
    # Second output: confidenceScore
    builder.add_slice(
        name='extract_confidence',
        input_name='sigmoid_output',
        output_name='confidenceScore',
        axis='C',
        start_index=1,
        end_index=2
    )
    
    # Create the model
    model = ct.models.MLModel(builder.spec)
    
    # Set metadata
    model.author = 'JubileeMobileBay Team'
    model.short_description = 'Placeholder model for jubilee event prediction'
    model.version = '1.0.0'
    model.license = 'MIT'
    
    return model

if __name__ == "__main__":
    print("Creating placeholder Core ML model...")
    
    # Create the model
    model = create_placeholder_model()
    
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
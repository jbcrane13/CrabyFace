#!/usr/bin/env python3
"""
Jubilee Prediction Model Training Script
Creates a Core ML model with multiple outputs for jubilee event prediction
"""

import numpy as np
import coremltools as ct
from sklearn.ensemble import RandomForestRegressor
from sklearn.multioutput import MultiOutputRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error, r2_score
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
    # Optimal conditions: warm temps (75-85°F), low wind (<5 mph), low DO (<4 mg/L)
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
    
    # Calculate confidence scores based on data stability
    temp_diff = np.abs(air_temp - water_temp)
    temp_stability = 1.0 - (temp_diff / 20.0)
    wind_stability = 1.0 - (wind_speed / 25.0)
    confidence = (temp_stability + wind_stability) / 2.0
    confidence = np.clip(confidence, 0.3, 0.95)
    
    # Create DataFrame
    data = pd.DataFrame({
        'airTemperature': air_temp,
        'waterTemperature': water_temp,
        'windSpeed': wind_speed,
        'dissolvedOxygen': dissolved_oxygen,
        'jubileeProbability': probability,
        'confidenceScore': confidence
    })
    
    return data

# Train the model
def train_jubilee_model():
    """Train a multi-output regression model for jubilee prediction"""
    
    print("Generating training data...")
    data = generate_training_data(n_samples=20000)
    
    # Prepare features and targets
    feature_columns = ['airTemperature', 'waterTemperature', 'windSpeed', 'dissolvedOxygen']
    target_columns = ['jubileeProbability', 'confidenceScore']
    
    X = data[feature_columns].values
    y = data[target_columns].values
    
    # Split data
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    print(f"Training data shape: {X_train.shape}")
    print(f"Test data shape: {X_test.shape}")
    
    # Create and train multi-output model
    print("\nTraining multi-output random forest model...")
    base_regressor = RandomForestRegressor(n_estimators=100, random_state=42, n_jobs=-1)
    model = MultiOutputRegressor(base_regressor)
    model.fit(X_train, y_train)
    
    # Evaluate model
    print("\nEvaluating model...")
    y_pred = model.predict(X_test)
    
    for i, target in enumerate(target_columns):
        mse = mean_squared_error(y_test[:, i], y_pred[:, i])
        r2 = r2_score(y_test[:, i], y_pred[:, i])
        print(f"\n{target}:")
        print(f"  MSE: {mse:.4f}")
        print(f"  RMSE: {np.sqrt(mse):.4f}")
        print(f"  R² Score: {r2:.4f}")
    
    return model, feature_columns, target_columns

# Convert to Core ML
def convert_to_coreml(model, feature_columns, target_columns):
    """Convert scikit-learn model to Core ML format"""
    
    print("\nConverting to Core ML...")
    
    # Define input features
    input_features = []
    for feature in feature_columns:
        if feature == 'airTemperature':
            description = 'Air temperature in Fahrenheit'
        elif feature == 'waterTemperature':
            description = 'Water temperature in Fahrenheit'
        elif feature == 'windSpeed':
            description = 'Wind speed in miles per hour'
        elif feature == 'dissolvedOxygen':
            description = 'Dissolved oxygen in mg/L'
        else:
            description = feature
            
        input_features.append((feature, ct.models.datatypes.Double(), description))
    
    # Define output features
    output_features = []
    for target in target_columns:
        if target == 'jubileeProbability':
            description = 'Probability of jubilee event (0.0-1.0)'
        elif target == 'confidenceScore':
            description = 'Model confidence score (0.0-1.0)'
        else:
            description = target
            
        output_features.append((target, description))
    
    # Convert model
    coreml_model = ct.converters.sklearn.convert(
        model,
        input_features=input_features,
        output_feature_names=target_columns
    )
    
    # Set metadata
    coreml_model.author = 'JubileeMobileBay Team'
    coreml_model.short_description = 'Predicts jubilee events based on environmental conditions'
    coreml_model.version = '1.0.0'
    
    # Add descriptions to outputs
    spec = coreml_model.get_spec()
    for i, (name, desc) in enumerate(output_features):
        spec.description.output[i].shortDescription = desc
    
    # Update spec
    coreml_model = ct.models.MLModel(spec)
    
    return coreml_model

# Main execution
if __name__ == "__main__":
    # Train model
    model, feature_columns, target_columns = train_jubilee_model()
    
    # Convert to Core ML
    coreml_model = convert_to_coreml(model, feature_columns, target_columns)
    
    # Save model
    output_path = 'JubileePredictor.mlmodel'
    coreml_model.save(output_path)
    print(f"\nCore ML model saved to: {output_path}")
    
    # Test the Core ML model
    print("\nTesting Core ML model...")
    test_input = {
        'airTemperature': 80.0,
        'waterTemperature': 82.0,
        'windSpeed': 3.0,
        'dissolvedOxygen': 3.5
    }
    
    prediction = coreml_model.predict(test_input)
    print(f"\nTest prediction for optimal conditions:")
    print(f"  Input: {test_input}")
    print(f"  Jubilee Probability: {prediction['jubileeProbability']:.3f}")
    print(f"  Confidence Score: {prediction['confidenceScore']:.3f}")
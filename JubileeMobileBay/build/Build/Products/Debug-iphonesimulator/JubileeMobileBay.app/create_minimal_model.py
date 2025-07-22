#!/usr/bin/env python3
"""
Create a minimal Core ML model for JubileeMobileBay
This is the simplest possible model to get the app building
"""

import coremltools as ct
import numpy as np
from sklearn.linear_model import LinearRegression

# Create minimal training data
np.random.seed(42)
n_samples = 100

# 4 features: airTemp, waterTemp, windSpeed, dissolvedOxygen
X = np.random.rand(n_samples, 4)

# Simple output based on features
# Lower wind and DO = higher probability
y = 0.5 - 0.2 * X[:, 2] - 0.2 * X[:, 3] + 0.1 * X[:, 0] + 0.1 * X[:, 1]
y = np.clip(y, 0, 1)

# Train simple linear model
model = LinearRegression()
model.fit(X, y)

# Convert to Core ML
coreml_model = ct.converters.sklearn.convert(
    model,
    input_features=[
        ('airTemperature', ct.models.datatypes.Double()),
        ('waterTemperature', ct.models.datatypes.Double()),
        ('windSpeed', ct.models.datatypes.Double()),
        ('dissolvedOxygen', ct.models.datatypes.Double())
    ],
    output_feature_names='jubileeProbability'
)

# Set metadata
coreml_model.author = 'JubileeMobileBay'
coreml_model.short_description = 'Placeholder jubilee prediction model'
coreml_model.version = '1.0'

# Save
output_path = 'JubileePredictor.mlmodel'
coreml_model.save(output_path)

print(f"✅ Created {output_path}")
print("\nModel details:")
print(f"- Inputs: airTemperature, waterTemperature, windSpeed, dissolvedOxygen")
print(f"- Output: jubileeProbability")
print("\n⚠️  Note: This is a placeholder model. The app expects 'confidenceScore' output too,")
print("which will need to be calculated separately in the app code.")

# Test
test_input = {
    'airTemperature': 80.0,
    'waterTemperature': 82.0,
    'windSpeed': 3.0,
    'dissolvedOxygen': 3.5
}
result = coreml_model.predict(test_input)
print(f"\nTest prediction: {result['jubileeProbability']:.3f}")
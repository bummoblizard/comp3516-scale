# Short Python file to show how to generate predictions for each of the models.
# I've tried to do only basic computations from numpy - I hope these functions
# e.g. mean, log etc are present within Swift/Objective-C so that it's easy to
# port.

import numpy as np

# Input: arrays containing accelerometer data for the x-axis and z-axis, at 100Hz
# for 10sec (i.e. 1000 values expected).
# Here, it is simply random values.
x_raw = np.random.normal(size=1000)
z_raw = np.random.normal(size=1000)

# Output: the predictions from each of the 3 models.

# Step 1: Calculate the mean absolute amplitude (MAA)
# Subtract the mean from the full array
x_norm = x_raw - x_raw.mean()
z_norm = z_raw - z_raw.mean()

# Now, take the mean of the absolute values
x_maa = np.abs(x_norm).mean()
z_maa = np.abs(z_norm).mean()

# Step 2: Simply plug in the values for each model

# MODEL 1: Simple linear regression model
m1_intercept = 129.785961
m1_x = -367805.903315
m1_z = 406062.220123

m1_prediction = m1_intercept + m1_x * x_maa + m1_z * z_maa

# MODEL 2: Linear regression model with interactions
m2_intercept = -418.4162
m2_x = 433976.1456
m2_z = 1367812.5280
m2_xz = -1409073178.496

m2_prediction = m2_intercept + m2_x * x_maa + m2_z * z_maa + m2_xz * x_maa * z_maa

# MODEL 3: log transformed model
m3_intercept = 6.626590
m3_x = -5705.442683
m3_z = 2525.894158

m3_prediction = np.exp(
    m3_intercept + m3_x * x_maa + m3_z * z_maa
)  # take the exponential of the linear combination

print(m1_prediction, m2_prediction, m3_prediction)

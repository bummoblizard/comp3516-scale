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
# note: do not touch constants below! they are from the actual fitted models
m1_intercept = 129.785961
m1_x = -367805.903315
m1_z = 406062.220123
m1_mse = 3260.2169
m1_t_dist = 1.677
m1_cov_matrix = np.asarray(
    [
        [5.04065961e-01, -3.99255966e02, -3.21324068e02],
        [-3.99255966e02, 5.31714904e05, 3.02921752e04],
        [-3.21324068e02, 3.02921752e04, 4.84490253e05],
    ]
)

m1_comb_array = np.asarray([1, x_maa, z_maa]).reshape(-1, 1)  # Column vector
m1_var = np.sqrt(
    m1_mse * (m1_comb_array.T @ m1_cov_matrix @ m1_comb_array)
)  # The @ is matrix multiplication, the .T is transpose

m1_prediction = m1_intercept + m1_x * x_maa + m1_z * z_maa
m1_lower_bound = (m1_prediction - m1_t_dist * m1_var).item()
m1_upper_bound = (m1_prediction + m1_t_dist * m1_var).item()

print("Model 1:")
print(f"Estimated weight: {m1_prediction:.3f}g")
print(
    f"95% Confidence Interval for estimated weight: [{m1_lower_bound:.3f}g, {m1_upper_bound:.3f}g]"
)
print()

# MODEL 2: Linear regression model with interactions
m2_intercept = -418.4162
m2_x = 433976.1456
m2_z = 1367812.5280
m2_xz = -1409073178.496
m2_mse = 2370.297301720971
m2_t_dist = 1.678
m2_cov_matrix = np.asarray(
    [
        [7.16960988e00, -1.01480558e04, -1.20151644e04, 1.71328012e07],
        [-1.01480558e04, 1.47899810e07, 1.71333089e07, -2.50578575e10],
        [-1.20151644e04, 1.71333089e07, 2.09998306e07, -3.00572982e10],
        [1.71328012e07, -2.50578575e10, -3.00572982e10, 4.40373477e13],
    ]
)

m2_comb_array = np.asarray([1, x_maa, z_maa, x_maa * z_maa]).reshape(-1, 1)
m2_var = np.sqrt(m2_mse * (m2_comb_array.T @ m2_cov_matrix @ m2_comb_array))

m2_prediction = m2_intercept + m2_x * x_maa + m2_z * z_maa + m2_xz * x_maa * z_maa
m2_lower_bound = (m2_prediction - m2_t_dist * m2_var).item()
m2_upper_bound = (m2_prediction + m2_t_dist * m2_var).item()

print("Model 2:")
print(f"Estimated weight: {m2_prediction:.3f}g")
print(
    f"95% Confidence Interval for estimated weight: [{m2_lower_bound:.3f}g, {m2_upper_bound:.3f}g]"
)
print()

# MODEL 3: log transformed model
m3_intercept = 6.626590
m3_x = -5705.442683
m3_z = 2525.894158
m3_mse = 0.2096351825845287
m3_t_dist = 1.679
m3_cov_matrix = np.asarray(
    [
        [5.28150219e-01, -4.44846842e02, -3.16976527e02],
        [-4.44846842e02, 6.18116534e05, 2.19748690e04],
        [-3.16976527e02, 2.19748690e04, 4.85361130e05],
    ]
)

m3_comb_array = np.asarray([1, x_maa, z_maa]).reshape(-1, 1)
m3_var = np.sqrt(m3_mse * (m3_comb_array.T @ m3_cov_matrix @ m3_comb_array))

m3_log_pred = m3_intercept + m3_x * x_maa + m3_z * z_maa
m3_log_lower_bound = (m3_log_pred - m3_t_dist * m3_var).item()
m3_log_upper_bound = (m3_log_pred + m3_t_dist * m3_var).item()

m3_prediction = np.exp(m3_log_pred)  # take the exponential of the linear combination
m3_lower_bound = np.exp(m3_log_lower_bound)
m3_upper_bound = np.exp(m3_log_upper_bound)

print("Model 3:")
print(f"Estimated weight: {m3_prediction:.3f}g")
print(
    f"95% Confidence Interval for estimated weight: [{m3_lower_bound:.3f}g, {m3_upper_bound:.3f}g]"
)

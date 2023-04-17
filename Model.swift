// Swift version of generate_model_results.py, to be used in the mobile demo

import Foundation
import Accelerate

class WeightModel {

    // MODEL 1: Simple linear regression model
    class ModelOne {
        let intercept = 129.785961
        let x = -367805.903315
        let z = 406062.220123
        let mse = 3260.2169
        let t_dist = 1.677
        let cov_matrix = [
            [5.04065961e-01, -3.99255966e02, -3.21324068e02],
            [-3.99255966e02, 5.31714904e05, 3.02921752e04],
            [-3.21324068e02, 3.02921752e04, 4.84490253e05]
        ]

        func evaluate(maaX: Double, maaZ: Double) -> Double {
            let comb_array = [[1], [maaX], [maaZ]]
            let variable = mse * (comb_array.transpose() * cov_matrix * comb_array)[0][0]

            let prediction = intercept + x * maaX + z * maaZ
            let lower_bound = prediction - t_dist * variable.squareRoot()
            let upper_bound = prediction + t_dist * variable.squareRoot()

            print("Model 1:")
            print("Estimated weight: \(prediction)g")
            print("95% Confidence Interval: (\(lower_bound), \(upper_bound))")
            print("")
            return prediction
        }
    }

    // MODEL 2: Linear regression model with interactions
    class ModelTwo {
        let m2_intercept = -418.4162
        let m2_x = 433976.1456
        let m2_z = 1367812.5280
        let m2_xz = -1409073178.496
        let m2_mse = 2370.297301720971
        let m2_t_dist = 1.678
        let m2_cov_matrix = [
            [7.16960988e00, -1.01480558e04, -1.20151644e04, 1.71328012e07],
            [-1.01480558e04, 1.47899810e07, 1.71333089e07, -2.50578575e10],
            [-1.20151644e04, 1.71333089e07, 2.09998306e07, -3.00572982e10],
            [1.71328012e07, -2.50578575e10, -3.00572982e10, 4.40373477e13]
        ]

        func evaluate(maaX: Double, maaZ: Double) -> Double {
            let comb_array = [[1], [maaX], [maaZ], [maaX * maaZ]]
            let variable = m2_mse * (comb_array.transpose() * m2_cov_matrix * comb_array)[0][0]

            let prediction = m2_intercept + m2_x * maaX + m2_z * maaZ + m2_xz * maaX * maaZ
            let lower_bound = prediction - m2_t_dist * variable.squareRoot()
            let upper_bound = prediction + m2_t_dist * variable.squareRoot()

            print("Model 2:")
            print("Estimated weight: \(prediction)g")
            print("95% Confidence Interval: (\(lower_bound), \(upper_bound))")
            print("")
            return prediction
        }
    }

    // MODEL 3: log transformed model
    class ModelThree {
        let m3_intercept = 6.626590
        let m3_x = -5705.442683
        let m3_z = 2525.894158
        let m3_mse = 0.2096351825845287
        let m3_t_dist = 1.679
        let cov_matrix = [
            [5.28150219e-01, -4.44846842e02, -3.16976527e02],
            [-4.44846842e02, 6.18116534e05, 2.19748690e04],
            [-3.16976527e02, 2.19748690e04, 4.85361130e05]
        ]

        func evaluate(maaX: Double, maaZ: Double) -> Double {
            let comb_array = [[1], [maaX], [maaZ]]
            let variable = m3_mse * (comb_array.transpose() * cov_matrix * comb_array)[0][0]

            let log_prediction = m3_intercept + m3_x * maaX + m3_z * maaZ
            let log_lower_bound = log_prediction - m3_t_dist * variable.squareRoot()
            let log_upper_bound = log_prediction + m3_t_dist * variable.squareRoot()

            // take the exponential of the linear combination
            let prediction = exp(log_prediction)
            let lower_bound = exp(log_lower_bound)
            let upper_bound = exp(log_upper_bound)

            print("Model 3:")
            print("Estimated weight: \(prediction)g")
            print("95% Confidence Interval: (\(lower_bound), \(upper_bound))")
            print("")
            return prediction
        }
    }

    func predict(inputX: [Double], inputZ: [Double]){

        // Step 1: Calculate the mean absolute amplitude (MAA)
        // Subtract the mean from the full array

        let meanX = inputX.reduce(0, +) / Double(inputX.count)
        let meanZ = inputZ.reduce(0, +) / Double(inputZ.count)
        let normX = inputX.map { $0 - meanX }
        let normZ = inputZ.map { $0 - meanZ }

        // Now, take the mean of the absolute values
        let maaX = normX.map { abs($0) }.reduce(0, +) / Double(normX.count)
        let maaZ = normZ.map { abs($0) }.reduce(0, +) / Double(normZ.count)

        // Step 2: Simply plug in the values for each model
        _ = ModelOne().evaluate(maaX: maaX, maaZ: maaZ)
        _ = ModelTwo().evaluate(maaX: maaX, maaZ: maaZ)
        _ = ModelThree().evaluate(maaX: maaX, maaZ: maaZ)

    }
}

extension [[Double]]{

    func transpose() -> [[Double]] {
        guard let firstRow = self.first else { return [] }
        return firstRow.indices.map { index in
            self.map { $0[index] }
        }
    }

    static func *(lhs: [[Double]], rhs: [[Double]]) -> [[Double]]{

        // Matrix A: MxK
        // Matrix B: KxN

        if lhs[0].count != rhs.count {
            print("Matrix dimensions do not match!")
            fatalError()
        }

        // Define matrix row and column sizes
        let M = lhs.count
        let N = rhs[0].count
        let K = rhs.count

        let A = lhs.flatMap { $0 }
        let B = rhs.flatMap { $0 }
        // Create a matrix to hold the result
        var C = [[Double]](repeating: [Double](repeating: 0.0, count: N), count: M).flatMap { $0 }

        // Perform the matrix multiplication

        // Using A, B, C and M, N, K as defined

        // The stride is the distance between elements to read. 
        // To use all consecutive elements, set the stride to 1
        vDSP_mmulD(
            A, vDSP_Stride(1),
            B, vDSP_Stride(1),
            &C, vDSP_Stride(1),
            vDSP_Length(M),
            vDSP_Length(N),
            vDSP_Length(K)
        )

        // Reshape the matrix
        return C.chunked(into: N)
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension WeightModel {
    // Reference: https://www.advancedswift.com/matrix-math/

    func testMatrixMultiply(){
        let a: [[Double]] = [
            [3, 6],
            [1, 5],
            [8, 0]
        ]
        let b: [[Double]] = [
            [2],
            [6]
        ]
        print(a*b)
    }

    func testPredict() {
        // 1000 random values
        let inputX = (0..<1000).map { _ in Double.random(in: 0...1) }
        let inputZ = (0..<1000).map { _ in Double.random(in: 0...1) }
        predict(inputX: inputX, inputZ: inputZ)
    }
    
}

// WeightModel().testMatrixMultiply()
WeightModel().testPredict()
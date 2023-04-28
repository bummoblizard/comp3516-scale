// Swift version of generate_model_results.py, to be used in the mobile demo

import Foundation
import Accelerate

class WeightModel {
    
    enum Model: Hashable {
        case modelOne
        case modelTwo
        case modelThree
    }
    
    struct PredictionResult {
        var value: Double
        var upperBound: Double
        var lowerBound: Double
    }

    // MODEL 1: Simple linear regression model
    class ModelOne {
        let intercept = 206.722278
        let x = -211745.508432
        let z = 42899.895999
        // let mse = 3260.2169
        let t_dist = 1.677
        let cov_matrix = [
            [ 3.86827982e03, -7.51601005e05, -6.05802440e06],
            [-7.51601005e05,  3.23745300e09, -2.30770177e09],
            [-6.05802440e06, -2.30770177e09,  1.35601197e10]
        ]

        func evaluate(maaX: Double, maaZ: Double) -> PredictionResult {
            let comb_array = [[1], [maaX], [maaZ]]
            let variable = (comb_array.transpose() * cov_matrix * comb_array)[0][0]

            let prediction = intercept + x * maaX + z * maaZ
            let lower_bound = prediction - t_dist * variable.squareRoot()
            let upper_bound = prediction + t_dist * variable.squareRoot()

            print("Model 1:")
            print("Estimated weight: \(prediction)g")
            print("95% Confidence Interval: (\(lower_bound), \(upper_bound))")
            print("")
            return PredictionResult(value: prediction, upperBound: upper_bound, lowerBound: lower_bound)
        }
    }

    // MODEL 2: Linear regression model with interactions
    class ModelTwo {
        let m2_intercept = -412.6509
        let m2_x = 744862.7
        let m2_z = 1218036
        let m2_xz = -1803891068.96
        // let m2_mse = 2370.297301720971
        let m2_t_dist = 1.678
        let m2_cov_matrix = [
            [ 1.20756103e05, -1.81734049e08, -2.27939949e08, 3.41404045e11],
            [-1.81734049e08,  2.82581222e11,  3.41393001e11, -5.27291017e14],
            [-2.27939949e08,  3.41393001e11,  4.34357637e11, -6.47745393e14],
            [ 3.41404045e11, -5.27291017e14, -6.47745393e14, 9.94320958e17]
        ]

        func evaluate(maaX: Double, maaZ: Double) -> PredictionResult {
            let comb_array = [[1], [maaX], [maaZ], [maaX * maaZ]]
            let variable = (comb_array.transpose() * m2_cov_matrix * comb_array)[0][0]

            let prediction = m2_intercept + m2_x * maaX + m2_z * maaZ + m2_xz * maaX * maaZ
            let lower_bound = prediction - m2_t_dist * variable.squareRoot()
            let upper_bound = prediction + m2_t_dist * variable.squareRoot()

            print("Model 2:")
            print("Estimated weight: \(prediction)g")
            print("95% Confidence Interval: (\(lower_bound), \(upper_bound))")
            print("")
            return PredictionResult(value: prediction, upperBound: upper_bound, lowerBound: lower_bound)
        }
    }

    // MODEL 3: log transformed model
    class ModelThree {
        let m3_intercept = 5.837609
        let m3_x = -2368.177400
        let m3_z = 252.968484
        // let m3_mse = 0.2096351825845287
        let m3_t_dist = 1.679
        let cov_matrix = [
            [ 3.26631827e-01, -6.34640772e01, -5.11530621e02],
            [-6.34640772e01,  2.73365743e05, -1.94858925e05],
            [-5.11530621e02, -1.94858925e05,  1.14499645e06]
        ]

        func evaluate(maaX: Double, maaZ: Double) -> PredictionResult {
            let comb_array = [[1], [maaX], [maaZ]]
            let variable = (comb_array.transpose() * cov_matrix * comb_array)[0][0]

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
            return PredictionResult(value: prediction, upperBound: upper_bound, lowerBound: lower_bound)
        }
    }

    func predict(inputX: [Double], inputZ: [Double], with model: Model) -> PredictionResult {

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
        switch model{
        case .modelOne:
            return ModelOne().evaluate(maaX: maaX, maaZ: maaZ)
        case .modelTwo:
            return ModelTwo().evaluate(maaX: maaX, maaZ: maaZ)
        case .modelThree:
            return ModelThree().evaluate(maaX: maaX, maaZ: maaZ)
        }
    }
}


// Auxiliary functions for matrix operations
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
        predict(inputX: inputX, inputZ: inputZ, with: .modelOne)
    }
    
}

// WeightModel().testMatrixMultiply()
// WeightModel().testPredict()

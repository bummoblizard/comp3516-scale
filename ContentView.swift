//
//  ContentView.swift
//  universal-scale
//
//  Created by Ken Chung on 20/03/2023.
//

import SwiftUI
import CoreMotion
import Charts

class SensorsManager: ObservableObject {
    
    struct Acceleration: Identifiable {
        var data: CMAcceleration
        var id = UUID()
    }
    
    @Published var accelerometerData: [Acceleration] = []
    
    let motion = CMMotionManager()
    var timer: Timer?

    func startAccelerometers() {
       // Make sure the accelerometer hardware is available.
       if self.motion.isAccelerometerAvailable {
          self.motion.accelerometerUpdateInterval = 1.0 / 100.0  // 100 Hz
          self.motion.startAccelerometerUpdates()

          // Configure a timer to fetch the data.
          self.timer = Timer(fire: Date(), interval: (1.0/100.0),
                repeats: true, block: { (timer) in
             // Get the accelerometer data.
             if let data = self.motion.accelerometerData {
                 if self.accelerometerData.count == 100 * 10 { // 10 seconds of data
                     self.accelerometerData.removeFirst()
                 }
                 self.accelerometerData.append(Acceleration(data: data.acceleration))
             }
          })

          // Add the timer to the current run loop.
           RunLoop.current.add(self.timer!, forMode: .default)
       }
    }
    
}

struct ContentView: View {
    
    let generator = UIImpactFeedbackGenerator(style: .heavy)
    let predictionModel = WeightModel()
    
    @State var isVibrating = true
    @State var showingExporter = false
    @State var showingAlert = false
    @State var showingSuccessAlert = false
    @State var modelSelection: WeightModel.Model = .modelOne
    @ObservedObject var sensorsManager = SensorsManager()
    
//    @State var predictedValue: Double = 0.0
//    @State var upperBoundValue: Double = 0.0
//    @State var lowerBoundValue: Double = 0.0
    
    @State var isMeasuring = true
    @State var predictionResult: AggregatedResult? = nil
    
    struct AggregatedResult {
        var modelOne: WeightModel.PredictionResult
        var modelTwo: WeightModel.PredictionResult
        var modelThree: WeightModel.PredictionResult
        
        func result(for model: WeightModel.Model) -> WeightModel.PredictionResult {
            switch model {
            case .modelOne:
                return modelOne
            case .modelTwo:
                return modelTwo
            case .modelThree:
                return modelThree
            }
        }
    }
    
    var body: some View {
        TabView {
            predictionView
                .tabItem {
                    Label("Prediction", systemImage: "cube")
                }
            
            dataCollectionView
                .tabItem {
                    Label("Data collection", systemImage: "ruler")
                }
        }.onAppear {
            let _ = Timer.scheduledTimer(withTimeInterval: 1/10, repeats: true) { timer in
                if isVibrating {
                    generator.impactOccurred()
                }
            }
            sensorsManager.startAccelerometers()
            let _ = Timer.scheduledTimer(withTimeInterval: 1/10, repeats: true) { timer in
                
                if !isMeasuring || sensorsManager.accelerometerData.count < 100 * 10{
                    return
                }
                
                let inputX = sensorsManager.accelerometerData.map {$0.data.x}
                let inputZ = sensorsManager.accelerometerData.map {$0.data.z}

                predictionResult = AggregatedResult(
                    modelOne: predictionModel.predict(inputX: inputX, inputZ: inputZ, with: .modelOne),
                    modelTwo: predictionModel.predict(inputX: inputX, inputZ: inputZ, with: .modelTwo),
                    modelThree: predictionModel.predict(inputX: inputX, inputZ: inputZ, with: .modelThree)
                )
                
                isMeasuring = false
            }
        }
        
    }
    
    var dataCollectionView: some View {
        
        VStack {
            Group {
//                Chart(Array(sensorsManager.accelerometerData.enumerated()), id: \.element.id) { id, dataPoint in
//                    LineMark(x: .value("Time", id), y: .value("Acceleration", dataPoint.data.x), series: .value("Accelerometer", "X"))
//                        .foregroundStyle(.red)
//                }
//                Chart(Array(sensorsManager.accelerometerData.enumerated()), id: \.element.id) { id, dataPoint in
//                    LineMark(x: .value("Time", id), y: .value("Acceleration", dataPoint.data.y), series: .value("Accelerometer", "Y"))
//                        .foregroundStyle(.blue)
//                }
//
//                Chart(Array(sensorsManager.accelerometerData.enumerated()), id: \.element.id) { id, dataPoint in
//                    LineMark(x: .value("Time", id), y: .value("Acceleration", dataPoint.data.z), series: .value("Accelerometer", "Z"))
//                        .foregroundStyle(.green)
//                }
//                .chartLegend(position: .bottom)
                
            }
            
            HStack {
                Button("Save"){
                    guard sensorsManager.accelerometerData.count >= 1000 else {
                        showingAlert.toggle()
                        return
                    }
                    
                    let outputURL = URL.documentsDirectory.appending(path: UUID().uuidString + ".csv")
                    let xText = (sensorsManager.accelerometerData.map {String($0.data.x)}).joined(separator: ",")
                    let yText = (sensorsManager.accelerometerData.map {String($0.data.y)}).joined(separator: ",")
                    let zText = (sensorsManager.accelerometerData.map {String($0.data.z)}).joined(separator: ",")
                    
                    do {
                        try [xText,yText,zText].joined(separator: "\n").write(to: outputURL, atomically: true, encoding: .utf8)
                        showingSuccessAlert.toggle()
                    }catch {
                        showingAlert.toggle()
                        return
                    }
                }
                .alert("Data not ready", isPresented: $showingAlert) {
                    Button("Ok", role: .cancel) { }
                }
                .alert("Exported successfully", isPresented: $showingSuccessAlert) {
                    Button("Ok", role: .cancel) { }
                }
                
                Button("Clear"){
                    sensorsManager.accelerometerData.removeAll()
                }
                
            }
            
        }
        
    }
    
    var predictionView: some View {
        VStack {
            
            if let result = predictionResult?.result(for: modelSelection)  {
                
                Text("\(result.value)g")
                    .font(.title)
                    .monospacedDigit()
                
                Text("95% Confidence Interval: (\(result.lowerBound)g, \(result.upperBound)g)")
                    .font(.subheadline)
                    .monospacedDigit()
            }else{
                Text("Measuring")
                    .font(.title)
            }
            
            Picker("Prediction Model", selection: $modelSelection) {
                Text("Model 1 (Simple linear regression model)").tag(WeightModel.Model.modelOne)
                Text("Model 2 (Linear regression model with interactions)").tag(WeightModel.Model.modelTwo)
                Text("Model 3 (Log transformed model)").tag(WeightModel.Model.modelThree)
            }
            
            Spacer()
            
            Button("Measure"){
                sensorsManager.accelerometerData.removeAll()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0){
                    sensorsManager.accelerometerData.removeAll()
                }
                predictionResult = nil
                isMeasuring = true
            }
            
//            Toggle("Vibration (10Hz)", isOn: $isVibrating)
            
            
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

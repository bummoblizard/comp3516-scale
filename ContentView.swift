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
    @State var isVibrating = false
    @State var showingExporter = false
    @State var showingAlert = false
    @State var showingSuccessAlert = false
    @ObservedObject var sensorsManager = SensorsManager()
    
    var body: some View {
        VStack {
            
            Spacer()
            
            
            Toggle("Vibration (10Hz)", isOn: $isVibrating)
            
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
            
        }
        .padding()
        .onAppear {
            let _ = Timer.scheduledTimer(withTimeInterval: 1/10, repeats: true) { timer in
                if isVibrating {
                    generator.impactOccurred()
                }
            }
            sensorsManager.startAccelerometers()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

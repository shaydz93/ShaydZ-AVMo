import Foundation
import Combine

class VirtualEnvironmentViewModel: ObservableObject {
    @Published var isConnected = false
    @Published var latency = 0
    @Published var connectionStatus = "Disconnected"
    
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    
    func toggleConnection() {
        // Simulate connecting/disconnecting
        if isConnected {
            // Disconnect
            isConnected = false
            connectionStatus = "Disconnected"
            stopLatencySimulation()
        } else {
            // Connect with simulated delay
            connectionStatus = "Connecting..."
            
            // Simulate connection delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.isConnected = true
                self.connectionStatus = "Connected"
                self.startLatencySimulation()
            }
        }
    }
    
    private func startLatencySimulation() {
        // Simulate varying latency
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Simulate random latency between 30-120ms
            self.latency = Int.random(in: 30...120)
        }
        
        // Initial latency
        self.latency = Int.random(in: 30...120)
    }
    
    private func stopLatencySimulation() {
        timer?.invalidate()
        timer = nil
        latency = 0
    }
}

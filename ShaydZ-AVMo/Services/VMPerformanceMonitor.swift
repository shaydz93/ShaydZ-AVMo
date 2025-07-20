//
//  VMPerformanceMonitor.swift
//  ShaydZ-AVMo
//
//  Extracted performance monitoring logic for better separation of concerns
//

import Foundation
import Combine

/// Performance monitoring for virtual machines
class VMPerformanceMonitor: ObservableObject {
    
    struct PerformanceMetrics {
        let cpuUsage: Double
        let memoryUsage: Double
        let networkIO: (sent: Int64, received: Int64)
        let diskIO: (read: Int64, written: Int64)
        let frameRate: Int
        let latency: Int
        let timestamp: Date
    }
    
    @Published var currentMetrics: [String: PerformanceMetrics] = [:]
    
    private var monitoringTimers: [String: Timer] = [:]
    private let monitoringInterval: TimeInterval = 1.0
    
    /// Start monitoring performance for a VM
    func startMonitoring(vmId: String) {
        stopMonitoring(vmId: vmId) // Stop any existing monitoring
        
        let timer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { [weak self] _ in
            self?.updateMetrics(for: vmId)
        }
        
        monitoringTimers[vmId] = timer
    }
    
    /// Stop monitoring performance for a VM
    func stopMonitoring(vmId: String) {
        monitoringTimers[vmId]?.invalidate()
        monitoringTimers.removeValue(forKey: vmId)
        currentMetrics.removeValue(forKey: vmId)
    }
    
    /// Stop all monitoring
    func stopAllMonitoring() {
        monitoringTimers.values.forEach { $0.invalidate() }
        monitoringTimers.removeAll()
        currentMetrics.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func updateMetrics(for vmId: String) {
        // Simulate performance metrics collection
        // In a real implementation, this would interface with the VM hypervisor
        
        let metrics = PerformanceMetrics(
            cpuUsage: generateCPUUsage(),
            memoryUsage: generateMemoryUsage(),
            networkIO: generateNetworkIO(),
            diskIO: generateDiskIO(),
            frameRate: generateFrameRate(),
            latency: generateLatency(),
            timestamp: Date()
        )
        
        DispatchQueue.main.async {
            self.currentMetrics[vmId] = metrics
        }
    }
    
    private func generateCPUUsage() -> Double {
        // Simulate realistic CPU usage with some variability
        let base = 20.0
        let variation = Double.random(in: -10.0...30.0)
        return max(0.0, min(100.0, base + variation))
    }
    
    private func generateMemoryUsage() -> Double {
        // Simulate memory usage
        let base = 45.0
        let variation = Double.random(in: -5.0...15.0)
        return max(0.0, min(100.0, base + variation))
    }
    
    private func generateNetworkIO() -> (sent: Int64, received: Int64) {
        return (
            sent: Int64.random(in: 1024...10240),
            received: Int64.random(in: 2048...20480)
        )
    }
    
    private func generateDiskIO() -> (read: Int64, written: Int64) {
        return (
            read: Int64.random(in: 512...5120),
            written: Int64.random(in: 256...2560)
        )
    }
    
    private func generateFrameRate() -> Int {
        // Simulate frame rate with some occasional drops
        let rates = [60, 60, 60, 58, 60, 59, 60, 55]
        return rates.randomElement() ?? 60
    }
    
    private func generateLatency() -> Int {
        // Simulate network latency in milliseconds
        return Int.random(in: 5...25)
    }
    
    /// Get average metrics over a time period
    func getAverageMetrics(for vmId: String, over period: TimeInterval) -> PerformanceMetrics? {
        // This would calculate averages from stored historical data
        // For now, return current metrics
        return currentMetrics[vmId]
    }
    
    /// Check if VM performance is optimal
    func isPerformanceOptimal(for vmId: String) -> Bool {
        guard let metrics = currentMetrics[vmId] else { return false }
        
        return metrics.cpuUsage < 80.0 &&
               metrics.memoryUsage < 85.0 &&
               metrics.frameRate >= 55 &&
               metrics.latency < 30
    }
    
    /// Get performance recommendations
    func getPerformanceRecommendations(for vmId: String) -> [String] {
        guard let metrics = currentMetrics[vmId] else { return [] }
        
        var recommendations: [String] = []
        
        if metrics.cpuUsage > 80.0 {
            recommendations.append("Consider reducing CPU-intensive tasks or allocating more CPU cores")
        }
        
        if metrics.memoryUsage > 85.0 {
            recommendations.append("Consider increasing memory allocation or closing unused applications")
        }
        
        if metrics.frameRate < 50 {
            recommendations.append("Graphics performance is low - check GPU acceleration settings")
        }
        
        if metrics.latency > 50 {
            recommendations.append("Network latency is high - check network connection")
        }
        
        return recommendations
    }
}

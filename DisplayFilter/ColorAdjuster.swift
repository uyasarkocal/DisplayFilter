import SwiftUI
import Cocoa

class ColorAdjuster {
    static let shared = ColorAdjuster()
    private let adjustmentLock = NSLock()
    
    private var defaultGammaTableRed = [CGGammaValue](repeating: 0, count: 256)
    private var defaultGammaTableGreen = [CGGammaValue](repeating: 0, count: 256)
    private var defaultGammaTableBlue = [CGGammaValue](repeating: 0, count: 256)
    private var defaultGammaTableSampleCount: UInt32 = 0
    
    private var lastAppliedBrightness: [CGDirectDisplayID: Float] = [:]
    private var lastAppliedFilterColor: [CGDirectDisplayID: FilterColor] = [:]
    private var lastAppliedFilterIntensity: [CGDirectDisplayID: Float] = [:]
    
    private var updateTimer: Timer?
    private var pendingUpdates: [CGDirectDisplayID: (brightness: Float, filterColor: FilterColor, filterIntensity: Float)] = [:]
    
    private let minimumBrightness: Float = 0.05 // 5% minimum brightness
    
    private init() {
        updateDefaultGammaTables()
    }
    
    // Store the default gamma tables for each screen
    private func updateDefaultGammaTables() {
        for screen in NSScreen.screens {
            if let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID {
                CGGetDisplayTransferByTable(displayID, 256, &defaultGammaTableRed, &defaultGammaTableGreen, &defaultGammaTableBlue, &defaultGammaTableSampleCount)
            }
        }
    }
    
    // Schedule adjustments to be applied
    func setAdjustments(brightness: Float, filterColor: FilterColor, filterIntensity: Float, for screen: NSScreen) {
        guard let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
            return
        }
        
        let clampedBrightness = max(minimumBrightness, min(1, brightness))
        let clampedFilterIntensity = max(0, min(1, filterIntensity))
        
        pendingUpdates[displayID] = (brightness: clampedBrightness, filterColor: filterColor, filterIntensity: clampedFilterIntensity)
        
        if updateTimer == nil {
            updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.applyPendingUpdates()
            }
        }
    }
    
    // Apply scheduled adjustments
    private func applyPendingUpdates() {
        adjustmentLock.lock()
        defer { adjustmentLock.unlock() }
        
        for (displayID, update) in pendingUpdates {
            if lastAppliedBrightness[displayID] != update.brightness || 
               lastAppliedFilterColor[displayID] != update.filterColor ||
               lastAppliedFilterIntensity[displayID] != update.filterIntensity {
                applyAdjustments(brightness: update.brightness, filterColor: update.filterColor, filterIntensity: update.filterIntensity, for: displayID)
                lastAppliedBrightness[displayID] = update.brightness
                lastAppliedFilterColor[displayID] = update.filterColor
                lastAppliedFilterIntensity[displayID] = update.filterIntensity
            }
        }
        
        pendingUpdates.removeAll()
        
        if pendingUpdates.isEmpty {
            updateTimer?.invalidate()
            updateTimer = nil
        }
    }
    
    // Apply color adjustments to the screen
    private func applyAdjustments(brightness: Float, filterColor: FilterColor, filterIntensity: Float, for displayID: CGDirectDisplayID) {
        var adjustedRed = defaultGammaTableRed.map { $0 * CGGammaValue(brightness) }
        var adjustedGreen = defaultGammaTableGreen.map { $0 * CGGammaValue(brightness) }
        var adjustedBlue = defaultGammaTableBlue.map { $0 * CGGammaValue(brightness) }
        
        switch filterColor {
        case .orange:
            adjustedRed = adjustedRed.map { min($0 * CGGammaValue(1 + filterIntensity * 0.5), 1.0) }
            adjustedGreen = adjustedGreen.map { $0 * CGGammaValue(1 - filterIntensity * 0.3) }
            adjustedBlue = adjustedBlue.map { $0 * CGGammaValue(1 - filterIntensity * 0.8) }
        case .red:
            adjustedRed = adjustedRed.map { min($0 * CGGammaValue(1 + filterIntensity * 0.3), 1.0) }
            adjustedGreen = adjustedGreen.map { $0 * CGGammaValue(1 - filterIntensity * 0.8) }
            adjustedBlue = adjustedBlue.map { $0 * CGGammaValue(1 - filterIntensity * 0.8) }
        case .green:
            adjustedRed = adjustedRed.map { $0 * CGGammaValue(1 - filterIntensity * 0.8) }
            adjustedGreen = adjustedGreen.map { min($0 * CGGammaValue(1 + filterIntensity * 0.3), 1.0) }
            adjustedBlue = adjustedBlue.map { $0 * CGGammaValue(1 - filterIntensity * 0.8) }
        case .blue:
            adjustedRed = adjustedRed.map { $0 * CGGammaValue(1 - filterIntensity * 0.8) }
            adjustedGreen = adjustedGreen.map { $0 * CGGammaValue(1 - filterIntensity * 0.8) }
            adjustedBlue = adjustedBlue.map { min($0 * CGGammaValue(1 + filterIntensity * 0.3), 1.0) }
        case .none:
            break
        }
        
        CGSetDisplayTransferByTable(displayID, defaultGammaTableSampleCount, adjustedRed, adjustedGreen, adjustedBlue)
    }
    
    // Get current brightness for a screen
    func getCurrentBrightness(for screen: NSScreen) -> Float {
        guard let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
            return minimumBrightness
        }
        
        return max(minimumBrightness, lastAppliedBrightness[displayID] ?? 1.0)
    }
    
    // Get current filter color for a screen
    func getCurrentFilterColor(for screen: NSScreen) -> FilterColor {
        guard let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
            return .none
        }
        
        return lastAppliedFilterColor[displayID] ?? .none
    }
    
    // Get current filter intensity for a screen
    func getCurrentFilterIntensity(for screen: NSScreen) -> Float {
        guard let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
            return 0.0
        }
        
        return lastAppliedFilterIntensity[displayID] ?? 0.0
    }
    
    // Reset screen to default settings
    func resetAdjustments(for screen: NSScreen) {
        guard let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
            return
        }
        
        CGSetDisplayTransferByTable(displayID, defaultGammaTableSampleCount, defaultGammaTableRed, defaultGammaTableGreen, defaultGammaTableBlue)
        lastAppliedBrightness[displayID] = 1.0
        lastAppliedFilterColor[displayID] = .none
        lastAppliedFilterIntensity[displayID] = 0.0
    }
}
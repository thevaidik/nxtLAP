//
//  HapticManager.swift
//  motorsports
//

import UIKit

class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func trigger(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    func prepare() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.prepare()
        let selection = UISelectionFeedbackGenerator()
        selection.prepare()
    }
}

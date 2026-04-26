//
//  HapticManager.swift
//  motorsports
//

import UIKit

class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func trigger(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func buttonPress() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func racingImpact() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.prepare()
        generator.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            generator.impactOccurred()
        }
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

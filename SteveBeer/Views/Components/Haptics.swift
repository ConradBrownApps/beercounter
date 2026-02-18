import UIKit

enum Haptics {
    static func playAdd(for type: BeerType) {
        let style: UIImpactFeedbackGenerator.FeedbackStyle = (type == .tall) ? .medium : .light
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

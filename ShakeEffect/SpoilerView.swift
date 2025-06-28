import UIKit
import SwiftUI
class SpoilerView: UIView {
    private var emitterLayer: CAEmitterLayer?

    override class var layerClass: AnyClass { CAEmitterLayer.self }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) { fatalError() }

    func startAnimation() {
        guard let layer = self.layer as? CAEmitterLayer else { return }
        emitterLayer = layer

 
        layer.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
        layer.emitterShape    = .rectangle
        layer.emitterMode     = .surface
        layer.emitterSize     = bounds.size


        let area = bounds.width * bounds.height
        layer.emitterCells    = [makeCell(forArea: area)]
    }

    func stopAnimation() {
        emitterLayer?.emitterCells = nil
        emitterLayer = nil
    }

    private func makeCell(forArea area: CGFloat) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.contents       = makeCircleImage(diameter: 0.3, color: UIColor(white: 0, alpha: 1))

        cell.birthRate      = Float(area * 0.3)
        cell.lifetime       = 1
        cell.velocity       = 3
        cell.velocityRange  = 5
        cell.emissionRange  = .pi * 2
        cell.alphaSpeed     = -0.01
        cell.yAcceleration  = 4
        cell.spin           = .pi
        cell.spinRange      = .pi
        return cell
    }

    private func makeCircleImage(diameter: CGFloat, color: UIColor) -> CGImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: diameter, height: diameter))
        let img = renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: CGSize(width: diameter, height: diameter))
            ctx.cgContext.setFillColor(color.cgColor)
            ctx.cgContext.fillEllipse(in: rect)
        }
        return img.cgImage!
    }
}
struct VisualEffectView: UIViewRepresentable {
    let blurStyle: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}

//
//  PieChartView.swift
//  Utilities → PieChart
//

import UIKit

/// Модель сегмента (осталась прежней)

public final class PieChartView: UIView {
    
    // входные данные
    public var entities: [Entity] = [] {
        didSet { setNeedsDisplay() }
    }
    
    // 6 фирменных цветов
    private let segmentColors: [UIColor] = [
        UIColor(red: 0.38, green: 0.79, blue: 0.64, alpha: 1), // мягкий мятный
        UIColor(red: 0.99, green: 0.86, blue: 0.35, alpha: 1), // пастель-жёлтый
        UIColor(red: 0.40, green: 0.67, blue: 0.93, alpha: 1), // спокойный голубой
        UIColor(red: 0.96, green: 0.54, blue: 0.54, alpha: 1), // нежный красный
        UIColor(red: 0.73, green: 0.56, blue: 0.97, alpha: 1), // лавандовый
        UIColor(red: 0.70, green: 0.72, blue: 0.75, alpha: 1)  // светло-серый
    ]
    
    /// Толщина кольца (можно настроить)
    private let ringThickness: CGFloat = 32 // Сделать кольцо толще, чтобы центр был пустым
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    required init?(coder: NSCoder) { super.init(coder: coder); backgroundColor = .clear }
    
    // MARK: - Рисуем
    public override func draw(_ rect: CGRect) {
        guard !entities.isEmpty, let ctx = UIGraphicsGetCurrentContext() else { return }
        let processed = process(entities)
        let total = processed.reduce(0) { $0 + Double(truncating: $1.value as NSNumber) }
        let outerRadius = min(bounds.width, bounds.height) / 2 - 1
        let innerRadius = outerRadius - 8
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        ctx.setLineWidth(outerRadius - innerRadius)
        ctx.setLineCap(.butt)
        let gapAngle: CGFloat = .pi / 6 // 30 градусов разрыв
        let totalAngle: CGFloat = 2 * .pi - gapAngle
        var startAngle = -CGFloat.pi / 2 + gapAngle / 2
        for (index, ent) in processed.enumerated() {
            ctx.setStrokeColor(segmentColors[index].cgColor)
            let value = Double(truncating: ent.value as NSNumber)
            let endAngle = startAngle + CGFloat(value / total) * totalAngle
            ctx.addArc(center: center,
                       radius: (outerRadius + innerRadius) / 2,
                       startAngle: startAngle,
                       endAngle: endAngle,
                       clockwise: false)
            ctx.strokePath()
            startAngle = endAngle
        }
        // Центральный круг (фон)
        ctx.setFillColor(UIColor.systemGroupedBackground.cgColor)
        ctx.addArc(center: center, radius: innerRadius, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
        ctx.fillPath()
        // Легенда
        drawLegend(at: center, data: processed, total: total)
    }
    
 
    private func process(_ input: [Entity]) -> [Entity] {
        let sorted = input.sorted { $0.value > $1.value }
        guard sorted.count > 5 else { return sorted }

        let firstFive = sorted.prefix(5)
        let othersSum = sorted.dropFirst(5).reduce(Decimal.zero) { $0 + $1.value }
        // "Остальные" всегда последним
        return Array(firstFive) + [Entity(value: othersSum, label: "Остальные")]
    }
    
    // ───────── 2.  Легенда: перенос строк + центрирование ─────────
    private func drawLegend(at center: CGPoint, data: [Entity], total: Double) {
        let font  = UIFont.systemFont(ofSize: 9, weight: .regular) // Меньше размер
        let style = NSMutableParagraphStyle()
        style.alignment = .left               // выравниваем текст влево внутри блока
        
        // цветная точка + строка
        let paragraphs: [NSAttributedString] = data.enumerated().map { i, e in
            let percent = Double(truncating: e.value as NSNumber) / total * 100
            let percentString = String(format: "%g", round(percent * 10) / 10)
            let attr = NSMutableAttributedString(string: "● \(percentString)% \(e.label)",
                                                 attributes: [.font: font,
                                                              .paragraphStyle: style,
                                                              .foregroundColor: UIColor.label])
            attr.addAttribute(.foregroundColor, value: segmentColors[i], range: NSRange(location: 0, length: 1))
            return attr
        }
        
        let legend = paragraphs.reduce(NSMutableAttributedString()) {
            if !$0.string.isEmpty { $0.append(NSAttributedString(string: "\n")) }
            $0.append($1); return $0
        }
        
        // *** ограничиваем ширину, чтобы строки переносились ***
        let radius     = min(bounds.width, bounds.height) / 2 - ringThickness // больше отступа
        let maxWidth   = radius * 1.2
        let bounding   = legend.boundingRect(with: CGSize(width: maxWidth,
                                                          height: .greatestFiniteMagnitude),
                                             options: [.usesLineFragmentOrigin, .usesFontLeading],
                                             context: nil).size
        // центрируем блок легенды внутри круга с небольшим отступом
        let rect = CGRect(x: center.x - bounding.width/2,
                          y: center.y - bounding.height/2,
                          width: bounding.width,
                          height: bounding.height)
        legend.draw(in: rect)
    }
    // Публичный метод с анимацией звёздочки
    public func animateTransition(to newEntities: [Entity], duration: TimeInterval = 0.8) {
        // 1) поворот + fade-out старого слоя
        let fadeOut = CABasicAnimation(keyPath: "opacity")
        fadeOut.fromValue = 1
        fadeOut.toValue   = 0
        let rotate = CABasicAnimation(keyPath: "transform.rotation.z")
        rotate.fromValue = 0
        rotate.toValue   = CGFloat.pi        // 180°
        let group1 = CAAnimationGroup()
        group1.animations = [fadeOut, rotate]
        group1.duration   = duration / 2
        group1.timingFunction = CAMediaTimingFunction(name: .easeIn)
        layer.add(group1, forKey: "out")

        // обновляем данные ровно в середине анимации
        DispatchQueue.main.asyncAfter(deadline: .now() + duration / 2) { [weak self] in
            self?.entities = newEntities
            // 2) появление + оставшиеся 180°
            let fadeIn = CABasicAnimation(keyPath: "opacity")
            fadeIn.fromValue = 0
            fadeIn.toValue   = 1
            let rotate2 = CABasicAnimation(keyPath: "transform.rotation.z")
            rotate2.fromValue = CGFloat.pi
            rotate2.toValue   = CGFloat.pi * 2 // 360°
            let group2 = CAAnimationGroup()
            group2.animations = [fadeIn, rotate2]
            group2.duration   = duration / 2
            group2.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self?.layer.add(group2, forKey: "in")
        }
    }
}

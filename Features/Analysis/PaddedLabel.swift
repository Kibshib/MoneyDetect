//
//  PaddedLabel.swift
//  MoneyDetector
//
//  Created by mac on 19.07.2025.
//

import UIKit

final class PaddedLabel: UILabel {

    var textInsets = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.width  += textInsets.left + textInsets.right
        size.height += textInsets.top  + textInsets.bottom
        return size
    }
}

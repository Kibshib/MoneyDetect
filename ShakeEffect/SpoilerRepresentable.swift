import SwiftUI

struct SpoilerViewRepresentable: UIViewRepresentable {
    @Binding var isHidden: Bool
    var size: CGSize

    func makeUIView(context: Context) -> SpoilerView {
        SpoilerView(frame: CGRect(origin: .zero, size: size))
    }

    func updateUIView(_ uiView: SpoilerView, context: Context) {
        uiView.frame.size = size
        if isHidden {
            uiView.startAnimation()
        } else {
            uiView.stopAnimation()
        }
    }
}

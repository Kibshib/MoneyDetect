import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    typealias UIViewType = LottieAnimationView

    let name: String
    var loopMode: LottieLoopMode = .playOnce
    var onFinished: (() -> Void)?

    func makeUIView(context: Context) -> LottieAnimationView {

        let view = LottieAnimationView(name: name)
        view.contentMode = .scaleAspectFit
        view.loopMode = loopMode
        view.backgroundBehavior = .pauseAndRestore
        return view
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) {
        if !context.coordinator.didPlay {
            context.coordinator.didPlay = true
            uiView.play { finished in
                if finished {
                    onFinished?()
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinished: onFinished)
    }

    class Coordinator {
        var didPlay = false
        let onFinished: (() -> Void)?
        init(onFinished: (() -> Void)?) {
            self.onFinished = onFinished
        }
    }
}

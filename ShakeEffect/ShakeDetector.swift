import SwiftUI
import UIKit

struct ShakeDetector: UIViewControllerRepresentable {
    var onShake: () -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        class Host: UIViewController {
            var onShake: () -> Void
            init(onShake: @escaping ()->Void) {
                self.onShake = onShake; super.init(nibName:nil, bundle:nil)
            }
            required init?(coder: NSCoder){ fatalError() }
            override var canBecomeFirstResponder: Bool { true }
            override func viewDidLoad() {
                super.viewDidLoad()
                becomeFirstResponder()
            }
            override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
                if motion == .motionShake { onShake() }
            }
        }
        return Host(onShake: onShake)
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

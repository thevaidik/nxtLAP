import SwiftUI
import AuthenticationServices

// Amplify needs a UIWindow as a presentation anchor for the Web UI.
// This struct wraps an empty UIViewController to extract its view's window.
struct WindowAccessor: UIViewControllerRepresentable {
    @Binding var window: UIWindow?

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .clear
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let window = uiViewController.view.window {
            DispatchQueue.main.async {
                self.window = window
            }
        }
    }
}

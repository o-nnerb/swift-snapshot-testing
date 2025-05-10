import UIKit
import SwiftUI

@MainActor
protocol SizeListenerDelegate: AnyObject {

    func viewDidUpdateSize(_ size: CGSize)
}

@MainActor
class SizeListener {

    weak var delegate: SizeListenerDelegate? {
        willSet {
            newValue?.viewDidUpdateSize(size)
        }
    }
    
    private(set) var size: CGSize = .zero
    fileprivate weak var owningView: UIView?

    init() {}

    fileprivate func updateSize(_ size: CGSize) {
        self.size = size
        delegate?.viewDidUpdateSize(size)
    }

    func dispose() {
        owningView?.removeFromSuperview()
    }
}

// MARK: - UIView Extensions

private class UIViewSizeListener: UIView {

    let listener: SizeListener

    init(listener: SizeListener) {
        self.listener = listener
        super.init(frame: .zero)
        listener.owningView = self
    }
    
    required init?(coder: NSCoder) {
        nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard window != nil, let superview else {
            return
        }

        listener.updateSize(superview.bounds.size)
    }
}

extension UIView {

    func addSizeListener(_ listener: SizeListener) {
        let view = UIViewSizeListener(listener: listener)
        view.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(view, at: .zero)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: topAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor),
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}

// MARK: - SwiftUI Extensions

private struct ViewSizeListener: ViewModifier {

    let listener: SizeListener

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy -> Color in
                    let size = proxy.frame(in: .global).size

                    Task { @MainActor in
                        listener.updateSize(size)
                    }

                    return Color.black.opacity(.zero)
                }
                .edgesIgnoringSafeArea(.all)
            )
    }
}

extension View {

    func sizeListener(_ listener: SizeListener) -> some View {
        modifier(ViewSizeListener(listener: listener))
    }
}

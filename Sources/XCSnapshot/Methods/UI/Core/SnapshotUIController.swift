import UIKit
import SwiftUI

class SnapshotUIController: UIViewController {

    // MARK: - Internal properties

    override var shouldAutomaticallyForwardAppearanceMethods: Bool {
        return true
    }

    var contentSize: CGSize {
        if let size = configuration.size, size.width > .zero && size.height > .zero {
            return size
        } else {
            return sizeListener.size
        }
    }

    let configuration: LayoutConfiguration

    // MARK: - Private properties

    private var parentSafeAreaInsets: UIEdgeInsets? {
        (view.window ?? window ?? view.superview)?.safeAreaInsets
    }

    private let childController: UIViewController
    private let sizeListener: SizeListener

    private var isWaitingSnapshotSignal = false
    private let snapshotSignal = AsyncSignal()

    private weak var window: UIWindow?

    // MARK: - Inits

    init(_ view: UIView, with configuration: LayoutConfiguration) {
        let sizeListener = SizeListener()
        view.addSizeListener(sizeListener)
        self.childController = view.withController()
        self.configuration = configuration
        self.sizeListener = sizeListener
        super.init(nibName: nil, bundle: nil)
    }

    init(_ viewController: UIViewController, with configuration: LayoutConfiguration) {
        let sizeListener = SizeListener()
        viewController.view.addSizeListener(sizeListener)
        self.childController = viewController
        self.configuration = configuration
        self.sizeListener = sizeListener
        super.init(nibName: nil, bundle: nil)
    }

    init<Content: View>(_ content: Content, with configuration: LayoutConfiguration) {
        let sizeListener = SizeListener()
        let viewController = UIHostingController(rootView: content.sizeListener(sizeListener))
        self.childController = viewController
        self.configuration = configuration
        self.sizeListener = sizeListener
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    // MARK: - Super methods

    override func viewDidLoad() {
        super.viewDidLoad()
        attachChild()
        sizeListener.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setOverrideTraitCollection(configuration.traits, forChild: childController)
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        self.window = view.window
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateAdditionalSafeAreaInsets()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateAdditionalSafeAreaInsets()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.window = nil
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if isWaitingSnapshotSignal {
            isWaitingSnapshotSignal = false

            Task {
                await snapshotSignal.signal()
            }
        }
    }

    override func shouldAutomaticallyForwardRotationMethods() -> Bool {
        return true
    }

    // MARK: - Internal methods

    func layoutIfNeeded() {
        let view: UIView = childController.view ?? view

        let size = view.frame.size
        if size.height == .zero || size.width == .zero {
            view.setNeedsLayout()
            view.layoutIfNeeded()
        }
    }

    func snapshot() async throws -> UIImage {
        let traitCollection = configuration.traits

        isWaitingSnapshotSignal = true

        childController.view.setNeedsLayout()
        view.setNeedsLayout()
        view.layoutIfNeeded()

        try await snapshotSignal.wait()
        await snapshotSignal.lock()

        let contentSize = contentSize

        let fixedSize = CGSize(
            width: floor(contentSize.width),
            height: floor(contentSize.height)
        )

        let bounds = CGRect(
            x: childController.view.frame.midX - fixedSize.width / 2,
            y: childController.view.frame.midY - fixedSize.height / 2,
            width: fixedSize.width,
            height: fixedSize.height
        )

        let renderer = UIGraphicsImageRenderer(
            bounds: bounds,
            format: .init(for: traitCollection)
        )

        return renderer.image {
            view.layer.render(in: $0.cgContext)
        }
    }

    func detachChild() {
        sizeListener.dispose()

        childController.willMove(toParent: nil)
        childController.view.removeFromSuperview()
        childController.removeFromParent()

        childController.setValue(nil, forKey: "view")
    }

    // MARK: - Private methods

    private func attachChild() {
        addChild(childController)
        childController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(childController.view)
        childController.didMove(toParent: self)

        let heightAnchor = childController.view.heightAnchor.constraint(
            equalTo: view.heightAnchor,
            multiplier: 1
        )

        let widthAnchor = childController.view.widthAnchor.constraint(
            equalTo: view.widthAnchor,
            multiplier: 1
        )

        heightAnchor.priority = .fittingSizeLevel
        widthAnchor.priority = .fittingSizeLevel

        NSLayoutConstraint.activate([
            childController.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            childController.view.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            heightAnchor,
            widthAnchor
        ])

        setupSizeConstraints()

        updateChildAdditionalSafeAreaInsets()
    }

    private func setupSizeConstraints() {
        let size = configuration.size ?? .zero

        if size.height > .zero {
            let heightAnchor = childController.view.heightAnchor.constraint(
                equalToConstant: size.height
            )

            heightAnchor.priority = .required

            NSLayoutConstraint.activate([
                heightAnchor
            ])
        } else {
            childController.view.setContentHuggingPriority(.required, for: .vertical)
            childController.view.setContentCompressionResistancePriority(.required, for: .vertical)
        }

        if size.width > .zero {
            let widthAnchor = childController.view.widthAnchor.constraint(
                equalToConstant: size.width
            )

            widthAnchor.priority = .required

            NSLayoutConstraint.activate([
                widthAnchor
            ])
        } else {
            childController.view.setContentHuggingPriority(.required, for: .horizontal)
            childController.view.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
    }

    private func updateAdditionalSafeAreaInsets() {
        guard let safeAreaInsets = parentSafeAreaInsets else {
            additionalSafeAreaInsets = .zero
            return
        }

        additionalSafeAreaInsets = .init(
            top: safeAreaInsets.top == configuration.safeArea.top ? .zero : -safeAreaInsets.top,
            left: safeAreaInsets.left == configuration.safeArea.left ? .zero : -safeAreaInsets.left,
            bottom: safeAreaInsets.bottom == configuration.safeArea.bottom ? .zero : -safeAreaInsets.bottom,
            right: safeAreaInsets.right == configuration.safeArea.right ? .zero : -safeAreaInsets.right
        )

        updateChildAdditionalSafeAreaInsets()
    }

    private func updateChildAdditionalSafeAreaInsets() {
        // AdditionalSafeAreaInsets é .zero quando UIWindow não inicializou corretamente
        // ou quando o configuration.safeArea é igual a UIWindow.safeAreaInsets
        //
        // No primeiro cenário, precisamos corrigir para + ou para - para refletir a safeArea desejada.
        // No segundo cenário, só retornar .zero;
        func calculate(_ keyPath: KeyPath<UIEdgeInsets, CGFloat>) -> CGFloat {
            guard let safeAreaInsets = parentSafeAreaInsets else {
                return .zero
            }

            return configuration.safeArea[keyPath: keyPath] - safeAreaInsets[keyPath: keyPath]
        }

        childController.additionalSafeAreaInsets = .init(
            top: additionalSafeAreaInsets.top != .zero ? configuration.safeArea.top : calculate(\.top),
            left: additionalSafeAreaInsets.left != .zero ? configuration.safeArea.left : calculate(\.left),
            bottom: additionalSafeAreaInsets.bottom != .zero ? configuration.safeArea.bottom : calculate(\.bottom),
            right: additionalSafeAreaInsets.right != .zero ? configuration.safeArea.right : calculate(\.right)
        )
    }
}

// MARK: - SizeListenerDelegate

extension SnapshotUIController: SizeListenerDelegate {

    private var needsWindowSizeUpdate: Bool {
        guard let size = configuration.size else {
            return true
        }
        
        return size.width == .zero || size.height == .zero
    }

    func viewDidUpdateSize(_ size: CGSize) {
        guard let window else {
            return
        }

        guard needsWindowSizeUpdate && !window.isKeyWindow else {
            return
        }

        let referenceSize = configuration.size ?? window.frame.size

        if referenceSize.height == .zero {
            window.frame.size.height = floor(size.height)
        }

        if referenceSize.width == .zero {
            window.frame.size.width = floor(size.width)
        }
    }
}

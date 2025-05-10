import Foundation
import UIKit

@MainActor
class WindowManager {

    // MARK: - Internal static properties

    static let shared = WindowManager(UIApplication.sharedIfAvailable)

    // MARK: - Private properties

    private var keyUnit: ThreadUnit?
    private var units: [ThreadUnit] = []

    private weak var application: UIApplication?

    // MARK: - Inits

    init(_ application: UIApplication?) {
        self.application = application
    }

    // MARK: - Internal methods

    func acquireWindow(
        isKeyWindow: Bool,
        maxConcurrentTests: Int
    ) async throws -> UIWindow {
        if isKeyWindow {
            return try await acquireKeyWindow()
        } else {
            return try await acquireRegularWindow(maxConcurrentTests: maxConcurrentTests)
        }
    }

    func releaseWindow(_ window: UIWindow) async {
        if window.isKeyWindow || keyUnit?.window === window {
            return await releaseKeyWindow(window)
        } else {
            return await releaseRegularWindow(window)
        }
    }

    // MARK: - Private methods

    private func acquireKeyWindow() async throws -> UIWindow {
        if let keyUnit {
            try await keyUnit.lock()
            return keyUnit.window
        }

        let windowScenes = application?.windowScenes

        if let keyWindow = windowScenes?.keyWindows.last {
            let unit = ThreadUnit(window: keyWindow)
            keyUnit = unit
            try await unit.lock()
            return keyWindow
        }

        let window: UIWindow

        if let windowScene = windowScenes?.first {
            window = UIWindow(windowScene: windowScene)
        } else {
            window = UIWindow()
        }

        #warning("Not Working")
        window.makeKeyAndVisible()
        let unit = ThreadUnit(window: window)
        keyUnit = unit
        try await unit.lock()
        return window
    }

    private func acquireRegularWindow(maxConcurrentTests: Int) async throws -> UIWindow {
        if units.count >= maxConcurrentTests {
            let units = units[0 ..< maxConcurrentTests]
            let unit = units.sorted(by: { $0.pendingTasks >= $1.pendingTasks }).first!
            try await unit.lock()
            unit.window.isHidden = false
            return unit.window
        }

        let window: UIWindow

        if let windowScene = application?.windowScenes.first {
            window = UIWindow(windowScene: windowScene)
        } else {
            window = UIWindow()
        }

        window.isHidden = false
        let unit = ThreadUnit(window: window)
        units.append(unit)
        try await unit.lock()
        return window
    }

    private func releaseKeyWindow(_ window: UIWindow) async {
        guard let keyUnit, keyUnit.window === window else {
            fatalError("Key Window is not the one we expect")
        }

        await keyUnit.unlock()
    }

    private func releaseRegularWindow(_ window: UIWindow) async {
        defer { window.isHidden = true }

        guard let (index, unit) = units.enumerated().first(where: { $1.window === window }) else {
            return
        }

        let pendingTasks = unit.pendingTasks
        if pendingTasks == .zero {
            units.remove(at: index)
        }

        await unit.unlock()
    }
}

extension WindowManager {

    @MainActor
    class ThreadUnit {

        private let _lock: AsyncLock
        let window: UIWindow

        private(set) var pendingTasks: Int = .zero

        init(window: UIWindow) {
            _lock = .init()
            self.window = window
        }

        func lock() async throws {
            pendingTasks += 1
            try await _lock.lock()
            pendingTasks -= 1
        }

        func unlock() async {
            await _lock.unlock()
        }
    }
}

// MARK: - SnapshotWindowConfiguration

struct SnapshotWindowConfiguration<Input: Sendable>: Sendable {
    let window: UIWindow
    let input: Input
}

extension SnapshotConfiguration {

    func withWindow<NewInput: Sendable>(
        drawHierarchyInKeyWindow: Bool,
        application: UIApplication?,
        operation: @escaping @Sendable (SnapshotWindowConfiguration<NewInput>, Pipeline<Input, Output>) async throws -> Pipeline<NewInput, Output>
    ) -> SnapshotConfiguration<NewInput, Output> {
        map { pipeline in
            Pipeline.start(NewInput.self) { @MainActor newInput in
                let windowManager = application?.windowManager ?? WindowManager.shared

                let window = try await windowManager.acquireWindow(
                    isKeyWindow: drawHierarchyInKeyWindow,
                    maxConcurrentTests: TestingSession.shared.maxConcurrentTests
                )

                let configuration = SnapshotWindowConfiguration(
                    window: window,
                    input: newInput
                )

                do {
                    let pipeline = try await operation(configuration, pipeline)
                    let output = try await pipeline(newInput)

                    await windowManager.releaseWindow(window)
                    return output
                } catch {
                    await windowManager.releaseWindow(window)
                    throw error
                }
            }
        }
    }
}

@MainActor
private var kApplicationWindowManager = 0
private extension UIApplication {

    var windowManager: WindowManager {
        if let windowManager = objc_getAssociatedObject(self, &kApplicationWindowManager) as? WindowManager {
            return windowManager
        }

        let windowManager = WindowManager(self)
        objc_setAssociatedObject(self, &kApplicationWindowManager, windowManager, .OBJC_ASSOCIATION_RETAIN)
        return windowManager
    }
}

// MARK: - SnapshotUIController extensions

extension Pipeline where Output == SnapshotUIController {

    func connectToWindow(_ configuration: SnapshotWindowConfiguration<Input>) -> Pipeline<Input, ViewOperationPayload> {
        chain { @MainActor in
            ViewOperationPayload(
                previousRootViewController: configuration.window.switchRoot($0),
                window: configuration.window,
                input: $0
            )
        }
    }
}

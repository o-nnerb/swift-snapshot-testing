import WebKit

extension WKWebView {

    func waitLoadingState() async {
        guard isLoading else {
            return
        }

        var subscription: NSKeyValueObservation?
        defer { subscription?.invalidate() }

        let stream = AsyncStream<Bool> { continuation in
            subscription = observe(\.isLoading, options: [.initial, .new]) {
                (webview, change) in
                if let loading = change.newValue {
                    continuation.yield(loading)

                    if !loading {
                        continuation.finish()
                    }
                }
            }
        }

        for await isLoading in stream {
            if !isLoading {
                return
            }
        }
    }
}

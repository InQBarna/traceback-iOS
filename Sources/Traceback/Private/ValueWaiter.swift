import Foundation

actor ValueWaiter<T: Sendable> {
    private var pendingValue: T?
    private var continuation: CheckedContinuation<T?, Never>?
    private var alreadyCalled = false

    func waitForValue(timeoutSeconds: TimeInterval) async -> T? {
        assert(!alreadyCalled)
        alreadyCalled = true
        if let pendingValue = self.pendingValue {
            self.pendingValue = nil
            return pendingValue
        }
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            Task {
                try? await Task.sleep(nanoseconds: UInt64(timeoutSeconds * 1_000_000_000))
                self.timeoutExpired()
            }
        }
    }

    func provideValue(_ value: T) {
        if let continuation = self.continuation {
            self.continuation = nil
            continuation.resume(returning: value)
        } else {
            self.pendingValue = value
        }
    }

    private func timeoutExpired() {
        if let continuation = self.continuation {
            self.continuation = nil
            continuation.resume(returning: nil)
        }
    }
}

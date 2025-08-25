//
//  Accessibility.swift
//  WindowManager
//
//  Created by Yoshimasa Niwa on 7/3/23.
//

import AppKit
@preconcurrency
import ApplicationServices
import Foundation

extension AXValue {
    var cgPoint: CGPoint? {
        var value: CGPoint = .zero
        guard AXValueGetValue(self, .cgPoint, &value) else {
            return nil
        }
        return value
    }

    var cgSize: CGSize? {
        var value: CGSize = .zero
        guard AXValueGetValue(self, .cgSize, &value) else {
            return nil
        }
        return value
    }
}

extension CGPoint {
    var accessibilityValue: AXValue? {
        var value = self
        return AXValueCreate(.cgPoint, &value)
    }
}

extension CGSize {
    var accessibilityValue: AXValue? {
        var value = self
        return AXValueCreate(.cgSize, &value)
    }
}

enum AccessibilityError: Error {
    case axError(AXError)
}

@MainActor
extension AXUIElement {
    func attribute<T: CFTypeRef>(for key: String) throws -> T {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(
            self, // element
            key as CFString, // attribute
            &value // value
        )
        guard error == .success, let value = value as? T else {
            throw AccessibilityError.axError(error)
        }
        return value
    }

    func setAttribute<T: CFTypeRef>(_ value: T, for key: String) throws {
        let error = AXUIElementSetAttributeValue(self, key as CFString, value)
        if error != .success {
            throw AccessibilityError.axError(error)
        }
    }
}

public enum Accessibility {
    private final actor TrustedProcess {
        @MainActor
        private static func isProcessTrusted(promptToUser: Bool = false) -> Bool {
            let options = [
                kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: promptToUser
            ] as CFDictionary

            return AXIsProcessTrustedWithOptions(options)
        }

        private var isPromptedToUser = false

        private var waitingTask: Task<Void, any Error>?
        private var waitingCount = 0

        func wait() async throws {
            let task: Task<Void, any Error>
            if let waitingTask {
                task = waitingTask
            } else {
                let promptToUser = !isPromptedToUser
                isPromptedToUser = true
                guard await !Self.isProcessTrusted(promptToUser: promptToUser) else {
                    return
                }
                // Reentrant.
                if let waitingTask {
                    task = waitingTask
                } else {
                    task = Task.detached {
                        while true {
                            try Task.checkCancellation()
                            try await SuspendingClock().sleep(until: .now + .seconds(3))
                            if await Self.isProcessTrusted() {
                                break
                            }
                        }
                    }
                    waitingTask = task
                }
            }

            defer {
                // Reentrant.
                waitingCount -= 1
                if waitingCount == 0 {
                    task.cancel()
                    waitingTask = nil
                }
            }
            waitingCount += 1
            try await task.value
        }
    }

    private static let trustedProcess = TrustedProcess()

    public static func waitForBeingProcessTrusted() async throws {
        try await trustedProcess.wait()
    }
}

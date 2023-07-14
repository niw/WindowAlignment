//
//  HotKey.swift
//  HotKey
//
//  Created by Yoshimasa Niwa on 7/5/23.
//

import AppKit
import Carbon
import Foundation

extension FourCharCode: ExpressibleByStringLiteral {
    public init(stringLiteral: StringLiteralType) {
        if let data = stringLiteral.data(using: .macOSRoman) {
            self.init(data.reduce(0) { result, data in
                // This `Self()` is needed or truncated to UInt8.
                result << 8 + Self(data)
            })
        } else {
            self.init(0)
        }
    }
}

private struct SerialIdentifier<T: Numeric> {
    private var value: T

    init(_ initialValue: T = 0) {
        value = initialValue
    }

    mutating func next() -> T {
        value = value + 1
        return value
    }
}

@MainActor
public final class HotKey {
    public enum KeyCode {
        // TODO: cover all virtual key codes, or find a better solution.
        case left
        case right
        case up
        case down
        case raw(UInt32)

        public var rawValue: UInt32 {
            switch self {
            case .left:
                return UInt32(kVK_LeftArrow)
            case .right:
                return UInt32(kVK_RightArrow)
            case .up:
                return UInt32(kVK_UpArrow)
            case .down:
                return UInt32(kVK_DownArrow)
            case .raw(let value):
                return value
            }
        }
    }

    public struct Modifiers: OptionSet {
        public var rawValue: UInt32

        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        public init(modifierFlags: NSEvent.ModifierFlags) {
            rawValue = 0
            if contains(.shift) {
                insert(.shift)
            }
            if contains(.control) {
                insert(.control)
            }
            if contains(.option) {
                insert(.option)
            }
            if contains(.command) {
                insert(.command)
            }
        }

        public static let shift = Modifiers(rawValue: UInt32(shiftKey))
        public static let control = Modifiers(rawValue: UInt32(controlKey))
        public static let option = Modifiers(rawValue: UInt32(optionKey))
        public static let command = Modifiers(rawValue: UInt32(cmdKey))
    }

    public typealias Handler = () -> Void
    private typealias Identifier = UInt32

    private static var sharedEventHandler: CarbonEventHandler?
    private static var registeredHotKeys = [Identifier: HotKey]() {
        didSet {
            guard oldValue != registeredHotKeys else {
                return
            }

            if registeredHotKeys.isEmpty {
                sharedEventHandler = nil
            }
        }
    }

    private static let signature = OSType("WAhk")
    private static var serialIdentifier = SerialIdentifier<Identifier>()

    public static func add(
        keyCode: KeyCode,
        modifiers: Modifiers,
        handler: @escaping Handler
    ) -> HotKey? {
        let identifier = serialIdentifier.next()
        let hotKeyID = EventHotKeyID(signature: signature, id: identifier)

        var hotKeyRef: EventHotKeyRef?
        if RegisterEventHotKey(
            keyCode.rawValue, // inHotKeyCode
            modifiers.rawValue, // inHotKeyModifiers
            hotKeyID, // inHotKeyID
            GetEventMonitorTarget(), // inTarget
            .zero, // inOptions
            &hotKeyRef // outRef
        ) != noErr {
            return nil
        }
        guard let hotKeyRef else {
            return nil
        }

        if sharedEventHandler == nil {
            sharedEventHandler = CarbonEventHandler(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyPressed)
            ) { eventRef in
                var hotKeyID = EventHotKeyID()
                withUnsafeMutableBytes(of: &hotKeyID) { hotKeyIDBuffer in
                    if GetEventParameter(
                        eventRef, // inEvent
                        EventParamName(kEventParamDirectObject), // inName
                        EventParamType(typeEventHotKeyID), // inDesiredType
                        nil, // outActualType
                        hotKeyIDBuffer.count, // inBufferSize
                        nil, // outActualSize
                        hotKeyIDBuffer.baseAddress // outData
                    ) != noErr {
                        return
                    }
                }

                guard hotKeyID.signature == signature else {
                    return
                }

                let hotKey = registeredHotKeys[hotKeyID.id]
                guard let hotKey else {
                    return
                }

                hotKey.handler()
            }
        }

        return HotKey(
            identifier: identifier,
            hotKeyRef: hotKeyRef,
            handler: handler
        )
    }

    private let identifier: Identifier
    private let hotKeyRef: EventHotKeyRef
    private let handler: Handler

    private init(
        identifier: UInt32,
        hotKeyRef: EventHotKeyRef,
        handler: @escaping Handler
    ) {
        self.identifier = identifier
        self.hotKeyRef = hotKeyRef
        self.handler = handler

        HotKey.registeredHotKeys[identifier] = self
    }

    deinit {
        let identifier = identifier
        let hotKeyRef = hotKeyRef

        Task {
            await MainActor.run {
                UnregisterEventHotKey(hotKeyRef)
                HotKey.registeredHotKeys[identifier] = nil
            }
        }
    }
}

// MARK: - Equatable

extension HotKey: Equatable {
    public static func == (lhs: HotKey, rhs: HotKey) -> Bool {
        lhs.identifier == rhs.identifier
    }
}

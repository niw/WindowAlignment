//
//  WindowManager.swift
//  WindowManager
//
//  Created by Yoshimasa Niwa on 7/6/23.
//

import AppKit
import Extern
import Foundation

private extension NSDeviceDescriptionKey {
    static let screenNumber = NSDeviceDescriptionKey("NSScreenNumber")
}

private extension NSScreen {
    static func screen(forDisplayIdentifier displayIdentifier: CGDirectDisplayID) -> NSScreen? {
        for screen in NSScreen.screens {
            if let screenNumber = screen.deviceDescription[.screenNumber] as? Int {
                if displayIdentifier == screenNumber {
                    return screen
                }
            }
        }
        return nil
    }
}

public enum WindowManager {
    private static var _systemWideElement: AXUIElement?

    private static var systemWideElement: AXUIElement {
        if let _systemWideElement {
            return _systemWideElement
        }
        let systemWideElement = AXUIElementCreateSystemWide()
        _systemWideElement = systemWideElement
        return systemWideElement
    }

    @MainActor
    public struct App {
        public static var focused: App? {
            guard let element: AXUIElement = try? systemWideElement.attribute(for: kAXFocusedApplicationAttribute) else {
                return nil
            }
            return App(element: element)
        }

        var element: AXUIElement

        public var focusedWindow: Window? {
            guard let element: AXUIElement = try? element.attribute(for: kAXFocusedWindowAttribute) else {
                return nil
            }
            return Window(element: element)
        }
    }

    public struct Screen {
        var screen: NSScreen

        public var visibleFrame: CGRect {
            CGRect(
                x: screen.visibleFrame.origin.x,
                y: screen.frame.height - screen.visibleFrame.maxY,
                width: screen.visibleFrame.width,
                height: screen.visibleFrame.height
            )
        }
    }

    @MainActor
    public struct Window {
        var element: AXUIElement

        public var screen: Screen? {
            guard let windowID = element.windowID else {
                return nil
            }
            let displayIdentifier = SkyLightService.main.displayIdentifier(forWindowID: windowID)
            guard let screen = NSScreen.screen(forDisplayIdentifier: displayIdentifier) else {
                return nil
            }
            return Screen(screen: screen)
        }

        public var position: CGPoint? {
            guard let value: AXValue = try? element.attribute(for: kAXPositionAttribute) else {
                return nil
            }
            return value.cgPoint
        }

        public var size: CGSize? {
            guard let value: AXValue = try? element.attribute(for: kAXSizeAttribute) else {
                return nil
            }
            return value.cgSize
        }

        public func move(to position: CGPoint) {
            guard let value = position.accessibilityValue else {
                return
            }
            do {
                try element.setAttribute(value, for: kAXPositionAttribute)
            } catch {
            }
        }

        public func resize(to size: CGSize) {
            guard let value = size.accessibilityValue else {
                return
            }
            do {
                try element.setAttribute(value, for: kAXSizeAttribute)
            } catch {
            }
        }
    }
}

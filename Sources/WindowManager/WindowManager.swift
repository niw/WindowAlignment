//
//  WindowManager.swift
//  WindowManager
//
//  Created by Yoshimasa Niwa on 7/6/23.
//

import AppKit
import Foundation

extension NSScreen {
    // `NSScreen` is using the primary screen left-bottom origin coordinate, Y up.
    // However, Accessibility APIs for such as `kAXPositionAttribute` is using
    // the primary screen left-under-the-menu-bar origin coordinate, Y down.
    public var visibleBounds: CGRect {
        // The first screen has the zero `origin`.
        // Note that `NSScreen.main` is the screen where the key window exists,
        // not the one has the zero `origin`.
        let primaryScreenHeightWithoutMenuBar = NSScreen.screens.first?.visibleFrame.maxY ?? 0.0
        return CGRect(
            x: visibleFrame.origin.x,
            y: primaryScreenHeightWithoutMenuBar - visibleFrame.maxY,
            width: visibleFrame.width,
            height: visibleFrame.height
        )
    }
}

private extension NSWorkspace {
    var runningApplicationThatOwnsMenuBar: NSRunningApplication? {
        NSWorkspace.shared.runningApplications.first { runningApplication in
            runningApplication.ownsMenuBar
        }
    }
}

private extension NSRunningApplication {
    var accessibilityElement: AXUIElement? {
        AXUIElementCreateApplication(processIdentifier)
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
            if let element: AXUIElement = try? systemWideElement.attribute(for: kAXFocusedApplicationAttribute) {
                return App(element: element)
            }
            // Some application, such as Google Chrome can't find by `kAXFocusedApplicationAttribute`.
            // Fallback to iterate running applications to find the one owns the menu bar.
            if let element = NSWorkspace.shared.runningApplicationThatOwnsMenuBar?.accessibilityElement {
                return App(element: element)
            }
            return nil
        }

        var element: AXUIElement

        public var focusedWindow: Window? {
            guard let element: AXUIElement = try? element.attribute(for: kAXFocusedWindowAttribute) else {
                return nil
            }
            return Window(element: element)
        }
    }

    @MainActor
    public struct Window {
        // This is public visibility with private name for the extension.
        public var _element: AXUIElement

        private var element: AXUIElement {
            _element
        }

        init(element: AXUIElement) {
            _element = element
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

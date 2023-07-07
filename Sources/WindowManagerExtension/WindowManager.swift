//
//  WindowManager.swift
//  WindowManagerExtension
//
//  Created by Yoshimasa Niwa on 7/6/23.
//

import AppKit
import Foundation
import WindowManager
import WindowManagerExtern

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

extension WindowManager.Window {
    private var element: AXUIElement {
        _element
    }

    public var screen: NSScreen? {
        guard let windowID = element.windowID else {
            return nil
        }
        let displayIdentifier = SkyLightService.main.displayIdentifier(forWindowID: windowID)
        return NSScreen.screen(forDisplayIdentifier: displayIdentifier)
    }
}

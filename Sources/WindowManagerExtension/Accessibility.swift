//
//  Accessibility.swift
//  WindowManagerExtension
//
//  Created by Yoshimasa Niwa on 7/3/23.
//

import AppKit
import Foundation
import WindowManagerExtern

extension AXUIElement {
    var windowID: CGWindowID? {
        var windowID: CGWindowID = 0
        _AXUIElementGetWindow(self, &windowID)
        return windowID
    }
}

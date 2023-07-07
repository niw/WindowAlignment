//
//  AppDelegate.swift
//  WindowAlignment
//
//  Created by Yoshimasa Niwa on 7/2/23.
//

import AppKit
import Foundation
import HotKey
import WindowManager
import WindowManagerExtension

@MainActor
final class AppDelegate: NSObject, ObservableObject {
    var localizedName: String {
        for case let infoDictionary? in [
            Bundle.main.localizedInfoDictionary,
            Bundle.main.infoDictionary
        ] {
            for key in [
                "CFBundleDisplayName",
                "CFBundleName"
            ] {
                if let localizedName = infoDictionary[key] as? String {
                    return localizedName
                }
            }
        }

        // Should not reach here.
        return ""
    }

    func terminate() {
        NSApp.terminate(nil)
    }

    var hotKeys = [HotKey]()
}

extension AppDelegate: NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        Task {
            try await Accessibility.waitForBeingProcessTrusted()
            // TODO: Make this behavior configurable.
            hotKeys = [
                HotKey.add(keyCode: .up, modifiers: [.shift, .command]) {
                    guard let window = WindowManager.App.focused?.focusedWindow,
                          let screen = window.screen
                    else {
                        return
                    }
                    let bounds = screen.visibleBounds
                    var origin = bounds.origin
                    var size = bounds.size
                    let gapWidth = size.width * 0.125
                    origin.x += gapWidth
                    size.width -= gapWidth * 2.0
                    window.move(to: origin)
                    window.resize(to: size)
                },
                HotKey.add(keyCode: .down, modifiers: [.shift, .command]) {
                    guard let window = WindowManager.App.focused?.focusedWindow,
                          let screen = window.screen
                    else {
                        return
                    }
                    let bounds = screen.visibleBounds
                    window.move(to: bounds.origin)
                    window.resize(to: bounds.size)
                },
            ].compactMap({ $0 })
        }
    }
}

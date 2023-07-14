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
import Scripting

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
                    let environment: (String) -> Double? = { name  in
                        switch name {
                        case "screen.width":
                            bounds.size.width
                        case "screen.height":
                            bounds.size.height
                        case "screen.x":
                            bounds.origin.x
                        case "screen.y":
                            bounds.origin.y
                        default:
                            nil
                        }
                    }
                    let runtime = Runtime(environment: environment)

                    do {
                        let codeMoveToX = try Runtime.Code.compile(source: "screen.x + screen.width * 0.125")
                        let codeMoveToY = try Runtime.Code.compile(source: "screen.y")
                        let codeResizeToWidth = try Runtime.Code.compile(source: "screen.width - (screen.width * 0.125) * 2")
                        let codeResizeToHeight = try Runtime.Code.compile(source: "screen.height")

                        guard let moveToX = try runtime.run(code: codeMoveToX),
                              let moveToY = try runtime.run(code: codeMoveToY),
                              let resizeToWidth = try runtime.run(code: codeResizeToWidth),
                              let resizeToHeight = try runtime.run(code: codeResizeToHeight)
                        else {
                            return
                        }
                        window.move(to: CGPoint(x: moveToX, y: moveToY))
                        window.resize(to: CGSize(width: resizeToWidth, height: resizeToHeight))
                    } catch {
                    }
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

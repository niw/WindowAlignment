//
//  AppDelegate.swift
//  WindowAlignment
//
//  Created by Yoshimasa Niwa on 7/2/23.
//

import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class AppDelegate: NSObject {
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

    func presentAboutPanel() {
        if (NSApp.activationPolicy() == .accessory) {
            NSApp.activate(ignoringOtherApps: true)
        }
        NSApp.orderFrontStandardAboutPanel()
    }

    func terminate() {
        NSApp.terminate(nil)
    }

    private(set) var loginItem: LoginItem?

    private(set) var service: Service?

    private var xdgConfigHomeURL: URL {
        if let xdgConfigHome = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"],
           !xdgConfigHome.isEmpty
        {
            URL(filePath: xdgConfigHome, directoryHint: .isDirectory)
        } else {
            URL(filePath: NSHomeDirectory(), directoryHint: .isDirectory).appending(component: ".config", directoryHint: .isDirectory)
        }
    }

    func reloadService() {
        let configFileURL = xdgConfigHomeURL.appending(component: "window_alignment.json")

        let service = Service(configFileURL: configFileURL)
        self.service = service

        Task {
            try await service.start()
        }
    }

    func openConfigFile() {
        guard let service = service else {
            return
        }
        NSWorkspace.shared.open(service.configFileURL)
    }
}

extension AppDelegate: NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        loginItem = LoginItem()
        reloadService()
    }
}

//
//  AppDelegate.swift
//  WindowAlignment
//
//  Created by Yoshimasa Niwa on 7/2/23.
//

import AppKit
import Foundation

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

    func presentAboutPanel() {
        if (NSApp.activationPolicy() == .accessory) {
            NSApp.activate(ignoringOtherApps: true)
        }
        NSApp.orderFrontStandardAboutPanel()
    }

    func terminate() {
        NSApp.terminate(nil)
    }

    @Published
    private(set) var loginItem: LoginItem?

    @Published
    private(set) var service: Service?

    func reloadService() {
        let configFilePath = (NSHomeDirectory() as NSString).appendingPathComponent(".window_alignment.json")

        let service = Service(configFilePath: configFilePath)
        self.service = service

        Task {
            try await service.start()
        }
    }

    func openConfigFile() {
        guard let service = service else {
            return
        }
        let configFileURL = URL(filePath: service.configFilePath)
        NSWorkspace.shared.open(configFileURL)
    }
}

extension AppDelegate: NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        loginItem = LoginItem()
        reloadService()
    }
}

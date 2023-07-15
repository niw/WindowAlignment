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

    func terminate() {
        NSApp.terminate(nil)
    }

    @Published
    private(set) var loginItem: LoginItem?

    @Published
    private(set) var service: Service?

    func reloadService() {
        let service = Service()
        self.service = service

        Task {
            try await service.start()
        }
    }
}

extension AppDelegate: NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        loginItem = LoginItem()
        reloadService()
    }
}

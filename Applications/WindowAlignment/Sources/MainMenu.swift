//
//  MainMenu.swift
//  WindowAlignment
//
//  Created by Yoshimasa Niwa on 7/2/23.
//

import Foundation
import SwiftUI

struct ServiceStatusView: View {
    var service: Service

    var body: some View {
        switch service.state {
        case .configError:
            Text(
                "Configuration Error",
                tableName: "MainMenu",
                comment: "A main menu item appears when there is an error in the configuration file."
            )
        case .error:
            Text(
                "Unknown Error",
                tableName: "MainMenu",
                comment: "A main menu item appears when there is an unknown error."
            )
        case .waitingProcessTrusted:
            Text(
                "Waiting Accessibility Access…",
                tableName: "MainMenu",
                comment: "A main menu item appears when the application is waiting Accessibility Access."
            )
        case .none, .ready:
            EmptyView()
        }
    }
}

struct LoginItemView: View {
    var loginItem: LoginItem

    var body: some View {
        @Bindable
        var loginItem = loginItem

        Toggle(isOn: $loginItem.isEnabled) {
            Text(
                "Start on Login",
                tableName: "MainMenu",
                comment: "A main menu item to start the application on login."
            )
        }
    }
}

struct MainMenu: View {
    @Environment(AppDelegate.self)
    private var appDelegate

    var body: some View {
        if let service = appDelegate.service {
            Section {
                ServiceStatusView(service: service)
            }
        }
        Section {
            Button {
                appDelegate.openConfigFile()
            } label: {
                Text(
                    "Open Configuration File",
                    tableName: "MainMenu",
                    comment: "A main menu item to open the configuration file."
                )
            }
            .keyboardShortcut("O")
            Button {
                appDelegate.reloadService()
            } label: {
                Text(
                    "Reload Configuration",
                    tableName: "MainMenu",
                    comment: "A main menu item to reload the configuration file."
                )
            }
            .keyboardShortcut("R")
        }
        Section {
            if let loginItem = appDelegate.loginItem {
                LoginItemView(loginItem: loginItem)
            }
            Button {
                appDelegate.presentAboutPanel()
            } label: {
                Text(
                    "About \(appDelegate.localizedName)",
                    tableName: "MainMenu",
                    comment: "A main menu item to present a window about the application."
                )
            }
            Button {
                appDelegate.terminate()
            } label: {
                Text(
                    "Quit \(appDelegate.localizedName)",
                    tableName: "MainMenu",
                    comment: "A main menu item to terminate the application."
                )
            }
            .keyboardShortcut("Q")
        }
    }
}

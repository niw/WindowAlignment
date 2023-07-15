//
//  MainMenu.swift
//  WindowAlignment
//
//  Created by Yoshimasa Niwa on 7/2/23.
//

import Foundation
import SwiftUI

struct ServiceStatusView: View {
    @ObservedObject
    var service: Service

    var body: some View {
        switch service.state {
        case .configError:
            Text("Configuration Error")
        case .error:
            Text("Unknown Error")
        case .waitingProcessTrusted:
            Text("Waiting Accessibility Access...")
        case .none, .ready:
            EmptyView()
        }
    }
}

struct LoginItemView: View {
    @ObservedObject
    var loginItem: LoginItem

    var body: some View {
       Toggle(isOn: $loginItem.isEnabled) {
            Text("Start on Login")
        }
    }
}

struct MainMenu: View {
    @EnvironmentObject
    private var appDelegate: AppDelegate

    var body: some View {
        if let service = appDelegate.service {
            Section {
                ServiceStatusView(service: service)
            }
        }
        Section {
            Button("Reload Configuration") {
                appDelegate.reloadService()
            }
            .keyboardShortcut("R")
        }
        Section {
            if let loginItem = appDelegate.loginItem {
                LoginItemView(loginItem: loginItem)
            }
            Button("Quit \(appDelegate.localizedName)") {
                appDelegate.terminate()
            }
            .keyboardShortcut("Q")
        }
    }
}

//
//  MainMenu.swift
//  WindowAlignment
//
//  Created by Yoshimasa Niwa on 7/2/23.
//

import Foundation
import SwiftUI

struct ServiceStatus: View {
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

struct MainMenu: View {
    @EnvironmentObject
    private var appDelegate: AppDelegate

    var body: some View {
        if let service = appDelegate.service {
            ServiceStatus(service: service)
        }

        Button("Reload Configuration") {
            appDelegate.reload()
        }
        .keyboardShortcut("R")
        Button("Quit \(appDelegate.localizedName)") {
            appDelegate.terminate()
        }
        .keyboardShortcut("Q")
    }
}

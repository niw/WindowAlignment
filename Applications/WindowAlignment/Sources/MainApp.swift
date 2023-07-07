//
//  MainApp.swift
//  WindowAlignment
//
//  Created by Yoshimasa Niwa on 7/2/23.
//

import Foundation
import SwiftUI

@main
struct MainApp: App {
    @NSApplicationDelegateAdaptor
    private var appDelegate: AppDelegate

    var body: some Scene {
        MenuBarExtra(appDelegate.localizedName, systemImage: "macwindow.on.rectangle") {
            MainMenu()
                // `@NSApplicationDelegateAdaptor` supposed to put the object in the Environment
                // as its documentation said, however, in reality, it only works for `WindowGroup` views.
                // Therefore we need to manually put it here for `MenuBarExtra` views.
                .environmentObject(appDelegate)
        }
    }
}

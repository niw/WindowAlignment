//
//  MainMenu.swift
//  WindowAlignment
//
//  Created by Yoshimasa Niwa on 7/2/23.
//

import Foundation
import SwiftUI

struct MainMenu: View {
    @EnvironmentObject
    private var appDelegate: AppDelegate

    var body: some View {
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

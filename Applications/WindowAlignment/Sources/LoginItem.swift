//
//  LoginItem.swift
//  WindowAlignment
//
//  Created by Yoshimasa Niwa on 7/14/23.
//

import Foundation
import Observation
import ServiceManagement

private extension SMAppService {
    var isEnabled: Bool {
        status == .enabled
    }
}

@MainActor
@Observable
final class LoginItem {
    var isEnabled: Bool {
        didSet {
            guard isEnabled != oldValue else {
                return
            }
            update()
        }
    }

    @ObservationIgnored
    private var isUpdating: Bool = false

    private func update() {
        guard !isUpdating else {
            return
        }
        isUpdating = true
        defer {
            isUpdating = false
        }

        do {
            if isEnabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
        }
        isEnabled = SMAppService.mainApp.isEnabled
    }

    init() {
        isEnabled = SMAppService.mainApp.isEnabled
    }
}

//
//  SkyLightService.swift
//  WindowManagerExtension
//
//  Created by Yoshimasa Niwa on 7/6/23.
//

import Foundation
import WindowManagerExtern

@MainActor
final class SkyLightService {
    static let main = SkyLightService(connectionID: SLSMainConnectionID())

    private let connectionID: Int32

    init(connectionID: Int32) {
        self.connectionID = connectionID
    }

    func displayIdentifier(forWindowID windowID: CGWindowID) -> CGDirectDisplayID {
        let uuidString = SLSCopyManagedDisplayForWindow(connectionID, windowID).takeRetainedValue()
        let uuid = CFUUIDCreateFromString(nil, uuidString)
        return CGDisplayGetDisplayIDFromUUID(uuid)
    }
}

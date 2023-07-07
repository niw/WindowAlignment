//
//  CarbonEventHandler.swift
//  HotKey
//
//  Created by Yoshimasa Niwa on 7/5/23.
//

import Carbon
import Foundation

@MainActor
final class CarbonEventHandler {
    typealias Handler = (EventRef) -> Void

    // Due to class initialization order, these are `var` and forcibly unwrapped.
    private var eventHandlerRef: EventHandlerRef!
    private var handler: Handler!

    init?(
        eventClass: OSType,
        eventKind: UInt32,
        handler: @escaping Handler
    ) {
        var eventTypeSpec = EventTypeSpec(
            eventClass: eventClass,
            eventKind: eventKind
        )

        var eventHandlerRef: EventHandlerRef?
        if InstallEventHandler(
            GetEventMonitorTarget(), // inTarget
            { (_, eventRef: EventRef?, userData: UnsafeMutableRawPointer?) -> OSStatus in
                if let eventRef, let userData {
                    let this = Unmanaged<CarbonEventHandler>.fromOpaque(userData).takeUnretainedValue()
                    this.handleEvent(eventRef: eventRef)
                }
                return noErr
            }, // inHandler
            1, // inNumTypes
            &eventTypeSpec, // inList
            Unmanaged.passUnretained(self).toOpaque(), // inUserData
            &eventHandlerRef // outRef
        ) != noErr {
            return nil
        }
        guard let eventHandlerRef else {
            return nil
        }

        self.eventHandlerRef = eventHandlerRef
        self.handler = handler
    }

    deinit {
        // `eventHandlerRef` here must not be `nil`.
        let eventHandlerRef = eventHandlerRef
        Task {
            await MainActor.run {
                RemoveEventHandler(eventHandlerRef)
            }
        }
    }

    private func handleEvent(eventRef: EventRef) {
        handler(eventRef)
    }
}

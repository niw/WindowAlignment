//
//  Service.swift
//  WindowAlignment
//
//  Created by Yoshimasa Niwa on 7/13/23.
//

import Foundation
import HotKey
import WindowManager
import WindowManagerExtension
import Scripting

private extension Config {
    static func load(from configFileURL: URL) throws -> Self {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let data = try Data(contentsOf: configFileURL)
        return try decoder.decode(self, from: data)
    }

    func save(to configFileURL: URL) throws {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(self)
        try data.write(to: configFileURL)
    }

    static var example: Self {
        .init(actions: [
            .init(
                hotKey: .init(
                    keyCode: HotKey.KeyCode.up.rawValue,
                    modifiers: [.shift, .command]
                ),
                move: .init(
                    x: "screen.width * 0.125",
                    y: "screen.y"
                ),
                resize: .init(
                    width: "screen.width - (screen.width * 0.125) * 2",
                    height: "screen.height"
                )
            ),
            .init(
                hotKey: .init(
                    keyCode: HotKey.KeyCode.down.rawValue,
                    modifiers: [.shift, .command]
                ),
                move: .init(
                    x: "screen.x",
                    y: "screen.y"
                ),
                resize: .init(
                    width: "screen.width",
                    height: "screen.height"
                )
            )
        ])
    }
}

private extension HotKey.Modifiers {
    static func build(from modifiers: [Config.Action.HotKey.Modifiers]) -> Self {
        modifiers.reduce([]) { result, modifier in
            let hotKeyModifier: Self
            switch modifier {
            case .shift:
                hotKeyModifier = .shift
            case .control:
                hotKeyModifier = .control
            case .option:
                hotKeyModifier = .option
            case .command:
                hotKeyModifier = .command
            }
            return result.union(hotKeyModifier)
        }
    }
}

enum ServiceError: Error {
    case failedToAddHotKey(Service.Action)
}

@MainActor
final class Service: ObservableObject {
    struct Action {
        var keyCode: HotKey.KeyCode
        var modifiers: HotKey.Modifiers

        struct MoveCode {
            var x: Runtime.Code
            var y: Runtime.Code
        }

        struct ResizeCode {
            var width: Runtime.Code
            var height: Runtime.Code
        }

        var moveCode: MoveCode?
        var resizeCode: ResizeCode?

        init(config action: Config.Action) throws {
            keyCode = HotKey.KeyCode.raw(action.hotKey.keyCode)
            modifiers = HotKey.Modifiers.build(from: action.hotKey.modifiers)
            moveCode = try action.move.map { move in
                try MoveCode(
                    x: .compile(source: move.x),
                    y: .compile(source: move.y)
                )
            }
            resizeCode = try action.resize.map { resize in
                try ResizeCode(
                    width: .compile(source: resize.width),
                    height: .compile(source: resize.height)
                )
            }
        }
    }

    private func hotKeyDidPress(for action: Action) {
        guard let window = WindowManager.App.focused?.focusedWindow,
              let screen = window.screen
        else {
            return
        }

        let screenBounds = screen.visibleBounds
        let windowSize = window.size
        let windowPosition = window.position

        let runtime = Runtime { name in
            switch name {
            case "screen.width":
                return screenBounds.size.width
            case "screen.height":
                return screenBounds.size.height
            case "screen.x":
                return screenBounds.origin.x
            case "screen.y":
                return screenBounds.origin.y
            case "window.width":
                return windowSize?.width ?? 0.0
            case "window.height":
                return windowSize?.height ?? 0.0
            case "window.x":
                return windowPosition?.x ?? 0.0
            case "window.y":
                return windowPosition?.y ?? 0.0
            default:
                return nil
            }
        }

        do {
            if let moveCode = action.moveCode,
               let x = try runtime.run(code: moveCode.x),
               let y = try runtime.run(code: moveCode.y) {
                window.move(to: CGPoint(x: x, y: y))
            }
            if let resizeCode = action.resizeCode,
               let width = try runtime.run(code: resizeCode.width),
               let height = try runtime.run(code: resizeCode.height) {
                window.resize(to: CGSize(width: width, height: height))
            }
        } catch {
        }
    }

    private var hotKeys = [HotKey]()

    private func addHotKey(for action: Action) throws {
        guard let hotKey = HotKey.add(
            keyCode: action.keyCode,
            modifiers: action.modifiers,
            handler: { [weak self] in
                self?.hotKeyDidPress(for: action)
            }
        ) else {
            throw ServiceError.failedToAddHotKey(action)
        }
        hotKeys.append(hotKey)
    }

    enum State: String, Equatable {
        case none
        case configError
        case error
        case waitingProcessTrusted
        case ready
    }

    @Published
    private(set) var state: State = .none

    func start() async throws {
        guard state == .none else {
            return
        }

        let actions: [Action]
        do {
            let configFilePath = (NSHomeDirectory() as NSString).appendingPathComponent(".window_alignment.json")
            let configFileURL = URL(filePath: configFilePath)

            if !FileManager.default.fileExists(atPath: configFilePath) {
                try Config.example.save(to: configFileURL)
            }

            let config = try Config.load(from: configFileURL)

            actions = try config.actions.map { action in
                try Action(config: action)
            }
        } catch {
            state = .configError
            throw error
        }

        state = .waitingProcessTrusted
        do {
            try await Accessibility.waitForBeingProcessTrusted()

            for action in actions {
                try addHotKey(for: action)
            }
        } catch {
            state = .error
            throw error
        }

        state = .ready
    }
}

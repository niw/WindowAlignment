//
//  Configuration.swift
//  WindowAlignment
//
//  Created by Yoshimasa Niwa on 7/13/23.
//

import Foundation

struct Config: Equatable, Codable {
    struct Action: Equatable, Codable {
        struct HotKey: Equatable, Codable {
            enum Modifiers: String, Equatable, Codable {
                case shift
                case control
                case option
                case command
            }

            var keyCode: UInt32
            var modifiers: [Modifiers]
        }

        struct Move: Equatable, Codable {
            var x: String
            var y: String
        }

        struct Resize: Equatable, Codable {
            var width: String
            var height: String
        }

        var hotKey: HotKey
        var move: Move?
        var resize: Resize?
    }

    var actions: [Action]
}

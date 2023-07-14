//
//  RuntimeTests.swift
//  ScriptingTest
//
//  Created by Yoshimasa Niwa on 7/13/23.
//

import XCTest
@testable import Scripting

final class RuntimeTests: XCTestCase {
    func testCompile() throws {
        let operations = try compile(expression:
            .multiply(
                .add(
                    .symbol("cat"),
                    .symbol("kitten")
                ),
                .number(1.0)
            )
        )
        XCTAssertEqual(operations, [
            .push(.variable("cat")),
            .push(.variable("kitten")),
            .add,
            .push(.value(1.0)),
            .multiply
        ])
    }

    func testEvaluate() throws {
        let variables: [String : Double] = [
            "cat": 1.0,
            "kitten": 2.0
        ]
        let result = try evaluate(operations: [
            .push(.variable("cat")),
            .push(.variable("kitten")),
            .add,
            .push(.value(3.0)),
            .multiply
        ]) { name in
            variables[name]
        }
        XCTAssertEqual(result, 9.0)
    }

    func testRuntime() throws {
        let code = try Runtime.Code.compile(source: "1 + 2 - (cat + kitten) * 2")

        let variables: [String: Double] = [
            "cat": 1.0,
            "kitten": 2.0
        ]
        let runtime = Runtime() { name in
            variables[name]
        }

        let result = try runtime.run(code: code)
        XCTAssertEqual(result, -3.0)
    }
}

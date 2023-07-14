//
//  ParserTests.swift
//  ScriptingTest
//
//  Created by Yoshimasa Niwa on 7/13/23.
//

import XCTest
@testable import Scripting

final class ParserTests: XCTestCase {
    func testParse() throws {
        let expression = try parse(tokens: [
            .name("cat"),
            .plusOperator,
            .number(1.0),
            .multiplyOperator,
            .number(2.0)
        ])
        XCTAssertEqual(expression,
            .add(
                .symbol("cat"),
                .multiply(
                    .number(1.0),
                    .number(2.0)
                )
            )
        )
    }
}

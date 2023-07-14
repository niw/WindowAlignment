//
//  TokenizerTests.swift
//  ScriptingTest
//
//  Created by Yoshimasa Niwa on 7/13/23.
//

import XCTest
@testable import Scripting

final class TokenizerTests: XCTestCase {
    func testTokenizeNames() throws {
        let tokens = try tokenize(source: "_cat cat.meow kitten2")
        XCTAssertEqual(tokens, [
            .name("_cat"),
            .name("cat.meow"),
            .name("kitten2")
        ])
    }

    func testTokenizeIntegerNumbers() throws {
        let tokens = try tokenize(source: "1 -2 30 -40")
        XCTAssertEqual(tokens, [
            .number(1.0),
            .number(-2.0),
            .number(30.0),
            .number(-40.0)
        ])
    }

    func testTokenizeFloatNumbers() throws {
        let tokens = try tokenize(source: "0.1 -2.0 3.0e10 -4.0e-10 5.0e+10")
        XCTAssertEqual(tokens, [
            .number(0.1),
            .number(-2.0),
            .number(3e10),
            .number(-4e-10),
            .number(5e10)
        ])
    }

    func testTokenizeOperators() throws {
        let tokens = try tokenize(source: "1 + -2 - 3 * 4 / 5")
        XCTAssertEqual(tokens, [
            .number(1.0),
            .plusOperator,
            .number(-2.0),
            .minusOperator,
            .number(3.0),
            .multiplyOperator,
            .number(4.0),
            .divideOperator,
            .number(5.0)
        ])
    }

    func testTokenizeParentheses() throws {
        let tokens = try tokenize(source: "(cat)")
        XCTAssertEqual(tokens, [
            .leftParenthesis,
            .name("cat"),
            .rightParenthesis
        ])
    }
}

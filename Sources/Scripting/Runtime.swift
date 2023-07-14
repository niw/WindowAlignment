//
//  Runtime.swift
//  Scripting
//
//  Created by Yoshimasa Niwa on 7/13/23.
//

import Foundation

enum RuntimeError: Error {
    case stackUnderflow
    case noVariableFound(String)
}

private extension Array {
    mutating func push(_ element: Element) {
        append(element)
    }

    mutating func pop() throws -> Element {
        guard let element = popLast() else {
            throw RuntimeError.stackUnderflow
        }
        return element
    }
}

enum Operand: Equatable, Codable {
    case variable(String)
    case value(Double)
}

enum Operation: Equatable, Codable {
    case push(Operand)
    case add
    case subtract
    case multiply
    case divide
}

func compile(expression: Expression) throws -> [Operation] {
    switch expression {
    case .symbol(let symbol):
        return [.push(.variable(symbol))]
    case .number(let number):
        return [.push(.value(number))]
    case .add(let left, let right):
        return try compile(expression: left) + compile(expression: right) + [.add]
    case .subtract(let left, let right):
        return try compile(expression: left) + compile(expression: right) + [.subtract]
    case .multiply(let left, let right):
        return try compile(expression: left) + compile(expression: right) + [.multiply]
    case .divide(let left, let right):
        return try compile(expression: left) + compile(expression: right) + [.divide]
    }
}

func evaluate(
    operations: [Operation],
    environment: (String) -> Double? = { _ in nil }
) throws -> Double? {
    func value(operand: Operand) throws -> Double {
        switch operand {
        case .variable(let name):
            guard let value = environment(name) else {
                throw RuntimeError.noVariableFound(name)
            }
            return value
        case .value(let value):
            return value
        }
    }

    var stack = [Operand]()
    for operation in operations {
        switch operation {
        case .push(let value):
            stack.push(value)
        case .add:
            let right = try value(operand: stack.pop())
            let left = try value(operand: stack.pop())
            stack.push(.value(left + right))
        case .subtract:
            let right = try value(operand: stack.pop())
            let left = try value(operand: stack.pop())
            stack.push(.value(left - right))
        case .multiply:
            let right = try value(operand: stack.pop())
            let left = try value(operand: stack.pop())
            stack.push(.value(left * right))
        case .divide:
            let right = try value(operand: stack.pop())
            let left = try value(operand: stack.pop())
            stack.push(.value(left / right))
        }
    }

    let result = try stack.last.map { operand in
        try value(operand: operand)
    }
    return result
}

public struct Runtime {
    public struct Code {
        var operations: [Operation]

        public static func compile(source: String) throws -> Self {
            let tokens = try tokenize(source: source)
            let expression = try parse(tokens: tokens)
            let operations = try Scripting.compile(expression: expression)
            return .init(operations: operations)
        }
    }

    public var environment: (String) -> Double?

    public init(environment: @escaping (String) -> Double?) {
        self.environment = environment
    }

    public func run(code: Code) throws -> Double? {
        try evaluate(operations: code.operations, environment: environment)
    }
}

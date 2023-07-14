//
//  Parser.swift
//  Scripting
//
//  Created by Yoshimasa Niwa on 7/13/23.
//

import Foundation

enum ParserError: Error {
    case notValueToken(Token)
    case notFullyParse([Token])
}

private extension Token {
    var parser: Parser<Token, Token> {
        satisfy(consume()) { result in
            result == self
        }
    }
}

enum Expression: Equatable, Codable {
    case symbol(String)
    case number(Double)
    indirect case add(Expression, Expression)
    indirect case subtract(Expression, Expression)
    indirect case multiply(Expression, Expression)
    indirect case divide(Expression, Expression)
}

private typealias ExpressionParser = Parser<Token, Expression>

private let groupFactorPart: ExpressionParser = bind(Token.leftParenthesis.parser) { _ in
    bind(expression) { output in
        bind(Token.rightParenthesis.parser) { _ in
            result(output)
        }
    }
}
private let valueFactorPart: ExpressionParser = bind(consume()) { valueToken in
    switch valueToken {
    case .name(let name):
        return result(.symbol(name))
    case .number(let number):
        return result(.number(number))
    default:
        throw ParserError.notValueToken(valueToken)
    }
}
private let factor: ExpressionParser = or(groupFactorPart, valueFactorPart)

private let termPart: ExpressionParser = bind(factor) { left in
    bind(or(Token.multiplyOperator.parser, Token.divideOperator.parser)) { operatorToken in
        bind(term) { right in
            switch operatorToken {
            case .multiplyOperator:
                return result(Expression.multiply(left, right))
            case .divideOperator:
                return result(Expression.divide(left, right))
            default:
                // Should not reach here.
                fatalError()
            }
        }
    }
}
private let term: ExpressionParser = or(termPart, factor)

private let expressionPart: ExpressionParser = bind(term) { left in
    bind(or(Token.plusOperator.parser, Token.minusOperator.parser)) { operatorToken in
        bind(expression) { right in
            switch operatorToken {
            case .plusOperator:
                return result(Expression.add(left, right))
            case .minusOperator:
                return result(Expression.subtract(left, right))
            default:
                // Should not reach here.
                fatalError()
            }
        }
    }
}
private let expression: ExpressionParser = or(expressionPart, term)

func parse(tokens: [Token]) throws -> Expression {
    let (output, remaining) = try expression(tokens)
    guard remaining.isEmpty else {
        throw ParserError.notFullyParse(remaining)
    }
    return output
}

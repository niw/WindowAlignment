//
//  Tokenizer.swift
//  Scripting
//
//  Created by Yoshimasa Niwa on 7/13/23.
//

import Foundation

enum TokenizerError: Error {
    case notNumberExpression(String)
    case notFullyTokenize(String)
}

private extension CharacterSet {
    var parser: Parser<Unicode.Scalar, Unicode.Scalar> {
        satisfy(consume()) { output in
            contains(output)
        }
    }
}

enum Token: Equatable, Codable {
    case name(String)
    case number(Double)
    case leftParenthesis
    case rightParenthesis
    case plusOperator
    case minusOperator
    case multiplyOperator
    case divideOperator
}

private typealias TokenParser = Parser<Unicode.Scalar, Token>

private let whitespaces = CharacterSet.whitespacesAndNewlines.parser

private func ignoreWhitespaces<Output>(
    then parser: @escaping Parser<Unicode.Scalar, Output>
) -> Parser<Unicode.Scalar, Output> {
    bind(zeroOrMore(whitespaces)) { _ in
        parser
    }
}

private let period = CharacterSet(charactersIn: ".").parser

private let sign = CharacterSet(charactersIn: "+-").parser
private let exponentialIndicator = CharacterSet(charactersIn: "eE").parser
private let digit = CharacterSet.decimalDigits.parser
private let zeroDigit = CharacterSet(charactersIn: "0").parser
private let nonZeroDigit = CharacterSet(charactersIn: "123456789").parser
private let negativeSign = CharacterSet(charactersIn: "-").parser
private let exponentialPart = seq(one(exponentialIndicator), zeroOrOne(sign), oneOrMore(digit))
private let fractionPart = seq(one(period), oneOrMore(digit))
private let integerPart = or(
    seq(zeroOrOne(negativeSign), one(nonZeroDigit), zeroOrMore(digit)),
    seq(zeroOrOne(negativeSign), one(zeroDigit))
)
private let floatPart = or(
    seq(integerPart, fractionPart, exponentialPart),
    seq(integerPart, fractionPart),
    seq(integerPart, exponentialPart)
)
private let number = or(
    floatPart,
    integerPart
)
private let numberToken: TokenParser = bind(number) { output in
    let numberString = String(String.UnicodeScalarView(output))
    guard let double = Double(numberString) else {
        throw TokenizerError.notNumberExpression(numberString)
    }
    return result(.number(double))
}

private let namePartPrefixCharacter = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_").parser
private let namePartCharacter = CharacterSet(charactersIn: "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_").parser
private let namePart = seq(one(namePartPrefixCharacter), zeroOrMore(namePartCharacter))
private let name = or(
    // Not using `seq` due to recursive reference.
    bind(namePart) { namePart in
        bind(one(period)) { period in
            bind(name) { name in
                result(namePart + period + name)
            }
        }
    },
    namePart
)
private let nameToken: TokenParser = bind(name) { output in
    result(.name(String(String.UnicodeScalarView(output))))
}

private let leftParenthesisToken: TokenParser = bind(CharacterSet(charactersIn: "(").parser) { _ in
    result(.leftParenthesis)
}
private let rightParenthesisToken: TokenParser = bind(CharacterSet(charactersIn: ")").parser) { _ in
    result(.rightParenthesis)
}
private let plusOperatorToken: TokenParser = bind(CharacterSet(charactersIn: "+").parser) { _ in
    result(.plusOperator)
}
private let minusOperatorToken: TokenParser = bind(CharacterSet(charactersIn: "-").parser) { _ in
    result(.minusOperator)
}
private let multiplyOperatorToken: TokenParser = bind(CharacterSet(charactersIn: "*").parser) { _ in
    result(.multiplyOperator)
}
private let divideOperatorToken: TokenParser = bind(CharacterSet(charactersIn: "/").parser) { _ in
    result(.divideOperator)
}

private let tokenizer = oneOrMore(or(
    ignoreWhitespaces(then: leftParenthesisToken),
    ignoreWhitespaces(then: rightParenthesisToken),
    ignoreWhitespaces(then: numberToken),
    ignoreWhitespaces(then: nameToken),
    ignoreWhitespaces(then: plusOperatorToken),
    ignoreWhitespaces(then: minusOperatorToken),
    ignoreWhitespaces(then: multiplyOperatorToken),
    ignoreWhitespaces(then: divideOperatorToken)
))

func tokenize(source: String) throws -> [Token] {
    let (output, remaining) = try tokenizer(Array(source.unicodeScalars))
    guard remaining.isEmpty else {
        let remainingString = String(String.UnicodeScalarView(remaining))
        throw TokenizerError.notFullyTokenize(remainingString)
    }
    return output
}

//
//  ParserCombinator.swift
//  Scripting
//
//  Created by Yoshimasa Niwa on 7/13/23.
//

import Foundation

extension String: Error {}

typealias Parser<Input, Output> = ([Input]) throws -> (Output, [Input])

func result<Input, Output>(
    _ output: Output
) -> Parser<Input, Output> {
    { input in
        (output, input)
    }
}

func bind<Input, Output, T>(
    _ parser: @escaping Parser<Input, Output>,
    to factory: @escaping (Output) throws -> Parser<Input, T>
) -> Parser<Input, T> {
    { input in
        let (output, remaining) = try parser(input)
        let parser = try factory(output)
        return try parser(remaining)
    }
}

func consume<Input>() -> Parser<Input, Input> {
    { input in
        guard let first = input.first else {
            throw "No more input."
        }
        return (first, Array(input.dropFirst()))
    }
}

func satisfy<Input, Output>(
    _ parser: @escaping Parser<Input, Output>,
    when condition: @escaping (Output) -> Bool
) -> Parser<Input, Output> {
    bind(parser) { output in
        guard condition(output) else {
            throw "Not satisfied."
        }
        return result(output)
    }
}

func or<Input, Output>(
    _ parsers: Parser<Input, Output>...
) -> Parser<Input, Output> {
    { input in
        for parser in parsers {
            do {
                return try parser(input)
            } catch {
            }
        }
        throw "No parser matched."
    }
}

func seq<Input, Output>(
    _ parsers: Parser<Input, [Output]>...
) -> Parser<Input, [Output]> {
    { input in
        try parsers.reduce((result: [Output](), input: input)) { tuple, parser in
            let (result, remaining) = try parser(tuple.input)
            return (tuple.result + result, remaining)
        }
    }
}

func zero<Input, Output>() -> Parser<Input, [Output]> {
    result([])
}

func one<Input, Output>(
    _ parser: @escaping Parser<Input, Output>
) -> Parser<Input, [Output]> {
    bind(parser) { output in
        result([output])
    }
}

func zeroOrOne<Input, Output>(
    _ parser: @escaping Parser<Input, Output>
) -> Parser<Input, [Output]> {
    or(one(parser), zero())
}

func zeroOrMore<Input, Output>(
    _ parser: @escaping Parser<Input, Output>
) -> Parser<Input, [Output]> {
    { input in
        var result = [Output]()
        var input = input
        do {
            while true {
                let (output, remaining) = try parser(input)
                result.append(output)
                input = remaining
            }
        } catch {
        }
        return (result, input)
    }
}

func oneOrMore<Input, Output>(
    _ parser: @escaping Parser<Input, Output>
) -> Parser<Input, [Output]> {
    bind(one(parser)) { head in
        bind(zeroOrMore(parser)) { tail in
            result(head + tail)
        }
    }
}

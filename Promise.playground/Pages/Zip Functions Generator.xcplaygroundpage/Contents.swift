//: [Previous](@previous)

/*:

 # Zip Functions Generator

 This page generates `zip` functions for 3-*N* parameters. They all build on the
 two parameter variant, with `zip` for *N* parameters always delegating work
 to one with *N*-1 parameters.

 */

import Foundation

func types(_ n: Int) -> String {
    return (1...n).map { "T\($0)" }.joined(separator: ", ")
}


func createZip(_ n: Int) -> String {
    var output: String = "/// Zips \(n) promises of different types into a single Promise whose\n"
    output.append("/// type is a tuple of \(n) elements.\n")
    output.append("public static func zip<")
    output.append(types(n))
    output.append(">(")
    output.append((1...n-1).map { "_ p\($0): Promise<T\($0)>, " }.joined())
    output.append("_ last: Promise<T\(n)>) -> Promise<(\(types(n)))> {\n")

    output.append("return Promise<(\(types(n)))>(work: { (fulfill: @escaping ((\(types(n)))) -> Void, reject: @escaping (Error) -> Void) in\n")

    output.append("let zipped: Promise<(\(types(n-1)))> = zip(")
    output.append((1...n-1).map { "p\($0)" }.joined(separator: ", "))
    output.append(")\n\n")

    output.append("func resolver() -> Void {\n")
    output.append("if let zippedValue = zipped.value, let lastValue = last.value {\n")
    output.append("fulfill((")
    output.append((0...n-2).map { "zippedValue.\($0), " }.joined())
    output.append("lastValue))\n}\n}\n")

    output.append("zipped.then({ _ in resolver() }, reject)\n")
    output.append("last.then({ _ in resolver() }, reject)\n")

    output.append("})\n}")

    return output
}

func createZips(_ n: Int) -> String {
    return (3...n).map(createZip).joined(separator: "\n\n")
}

print(createZips(6))


//: [Next](@next)

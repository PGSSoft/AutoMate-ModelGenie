//
//  Writer.swift
//  ModelGenie
//
//  Created by Pawel Szot on 12/08/16.
//  Copyright © 2016 PSZOT. All rights reserved.
//

import Foundation

// MARK: - Other
let sharedSwiftLintOptions = "// swiftlint:disable identifier_name type_body_length trailing_comma file_length line_length"

private let identifierRegex: NSRegularExpression = {
    let regex = "\\W+"
    guard let expr = try? NSRegularExpression(pattern: regex, options: []) else {
        preconditionFailure("Couldn't initialize expression with given pattern")
    }
    return expr
}()

func asIdentifier(_ input: String) -> String {
    let range = NSRange(location: 0, length: input.characters.count)
    return identifierRegex.stringByReplacingMatches(in: input, options: [], range: range, withTemplate: "")
}

// MARK: - Strings readers
typealias StringsType = [String: String]
func readStrings(fromPath path: String) -> StringsType {
    guard let plist = NSDictionary(contentsOfFile: path) as? StringsType else {
        preconditionFailure("Couldn't load countries from Simulator")
    }

    return plist
}

func readRecursively(fileName: String, in directory: String, clouser: (_ fileName: String, _ path: String) -> Void) {
    let fileManager = FileManager.default
    guard let enumerator = fileManager.enumerator(atPath: directory) else {
        fatalError("Failed to find path: \(directory)")
    }

    while let element = enumerator.nextObject() as? String {
        let path = (directory as NSString).appendingPathComponent(element)
        var isDirectory: ObjCBool = false
        fileManager.fileExists(atPath: path, isDirectory: &isDirectory)

        if isDirectory.boolValue {
            readRecursively(fileName: fileName, in: path, clouser: clouser)
        } else if element == fileName {
            clouser(element, path)
        }
    }
}

func readStringsRecursively(fileName: String, in directory: String, closure: (_ fileName: String, _ path: String, _ content: StringsType) -> Void) {
    readRecursively(fileName: fileName, in: directory) { fileName, path in
        let content = readStrings(fromPath: path)
        closure(fileName, path, content)
    }
}

// MARK: - Message collections
typealias MessageCollection = Set<String>
typealias NamedMessageCollection = [String: MessageCollection]

func update(namedMessageCollection namedCollection: inout NamedMessageCollection, key: String, value: String) {
    var collection = namedCollection[key] ?? MessageCollection()
    collection.insert(value)
    namedCollection[key] = collection
}

// MARK: - String extension
extension String {
    var normalizedForLikeExpression: String {
        return replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "%@", with: "*")
    }
}

// MARK: - Writer
func write(toFile name: String, block: (_ writer: Writer) -> Void) {
    let writer = Writer()
    block(writer)
    writer.write(to: "\(Configuration.sourceDirectory)/\(Configuration.outputDirectory)/\(name).swift")
}

/// Helper for generating source code.
class Writer: CustomDebugStringConvertible {
    private let data = NSMutableData()
    private var indentation = 0

    func beginIndent() {
        indentation += 1
    }

    func finishIndent() {
        indentation -= 1
    }

    func write(to path: String) {
        do {
            try data.write(toFile: path, options: [])
        } catch {
            fatalError("Failed to write:" + path)
        }

        print("Saved to " + path)
    }

    func append(line: String) {
        assert(!line.contains("\n"))

        var indented = ""
        // ignore indentation for empty lines
        if !line.isEmpty {
            for _ in 0..<indentation {
                indented += "    "
            }
        }
        indented += line + "\n"

        guard let dataFromString = indented.data(using: String.Encoding.utf8) else {
            return
        }
        data.append(dataFromString)
    }

    var debugDescription: String {
        guard let content = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue) as String? else {
            fatalError()
        }
        return "Writer content:\n" + content
    }
}

// MARK: - JSON Writer
func writeToJson(collection: NamedMessageCollection, foriOS version: String) {
    for item in collection.sorted(by: { $0.0.key < $0.1.key }) {
        let fileUrl = Configuration.sourceDirectoryUrl
            .appendingPathComponent(Configuration.outputDirectory)
            .appendingPathComponent("Messages")
            .appendingPathComponent("\(item.key).json")
        let sortedValues = item.value.sorted()

        // Read existing file
        var existingMessages = [String: [String]]()
        if let data = try? Data(contentsOf: fileUrl),
            let json = try? JSONSerialization.jsonObject(with: data),
            let messages = json as? [String: [String]] {
            existingMessages = messages
        }

        // Add new messages
        existingMessages[version] = sortedValues

        // Save file
        if let data = try? JSONSerialization.data(withJSONObject: existingMessages, options: [.prettyPrinted]) {
            do {
                try data.write(to: fileUrl)
                print("Saved to: \(fileUrl.absoluteString)")
            } catch {
                print("Cannot save to: \(fileUrl.absoluteString)")
                fatalError(error.localizedDescription)
            }
        }
    }
}

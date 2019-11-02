import Foundation

func generateLanguages() {
    let locale = NSLocale(localeIdentifier: "en_US")
    let regex = "\\W+"

    guard let expr = try? NSRegularExpression(pattern: regex, options: []) else {
        preconditionFailure("Couldn't initialize expression with given pattern")
    }

    let simulatorLanguagesPath = Configuration.developerDirectory + "/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/System/Library/PrivateFrameworks/IntlPreferences.framework/Language.strings"

    let languagesDictionary = readStrings(fromPath: simulatorLanguagesPath)

    write(toFile: "SystemLanguage") { (writer) in

        writer.append(
"""
\(sharedSwiftLintOptions)

/// Enumeration describing available languages in the system.
public enum SystemLanguage: String, LaunchArgumentValue {
"""
        )
        for identifier in languagesDictionary.keys.sorted() {
            guard let displayName = locale.displayName(forKey: .identifier, value: identifier) else {
                continue
            }
            let range = NSRange(location: 0, length: displayName.count)
            let caseName = expr.stringByReplacingMatches(in: displayName, options: [], range: range, withTemplate: "")
            writer.append(
"""

    /// Automatically generated value for language \(caseName).
    case \(caseName) = \"\(identifier)\"
"""
            )
        }

        writer.append(line: "}")
    }

}

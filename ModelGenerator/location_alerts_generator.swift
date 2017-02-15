import Foundation

// swiftlint:disable:next function_body_length
func generateLocationAlerts() {
    let coreLocationPath = Configuration.developerDirectory + "/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/CoreLocation.framework"

    typealias MessageCollection = Set<String>
    typealias NamedMessageCollection = [String: MessageCollection]

    /// Iterates recursively throught directory content
    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func findServices(folderPath: String, alertsDictionary: inout NamedMessageCollection, optionsDictionary: inout NamedMessageCollection) {
        let serviceAlertsConfigurationFileName = "locationd.strings"
        let fileManager = FileManager.default
        guard let enumerator: FileManager.DirectoryEnumerator = fileManager.enumerator(atPath: folderPath) else {
            fatalError("Failed to find path: \(folderPath)")
        }

        while let element = enumerator.nextObject() as? String {
            let path = (folderPath as NSString).appendingPathComponent(element)
            var isDirectory: ObjCBool = false
            fileManager.fileExists(atPath: path, isDirectory: &isDirectory)

            if isDirectory.boolValue {
                // Search for file in nested folders:
                findServices(folderPath: path, alertsDictionary: &alertsDictionary, optionsDictionary: &optionsDictionary)
            } else if element == serviceAlertsConfigurationFileName {
                for configuration in readStrings(fromPath: path) {
                    // Removing prefix for system alerts:
                    var key = configuration.key
                    var value = configuration.value
                    value = value
                        .replacingOccurrences(of: "\"", with: "\\\"")
                        .replacingOccurrences(of: "%@", with: "*")

                    let updateConfiguration: ((String, String, inout NamedMessageCollection) -> Void) = { (key, value, dictionary) in
                        var collection = dictionary[key] ?? MessageCollection()
                        collection.insert(value)
                        dictionary[key] = collection
                    }

                    switch key {
                    case _ where key.uppercased().contains("LOCATION_CLIENT_PERMISSION_OK"):
                        key = "LocationAlertAllow"
                        updateConfiguration(key, value, &optionsDictionary)
                    case _ where key.uppercased().contains("DONT_ALLOW"):
                        key = "LocationAlertDeny"
                        updateConfiguration(key, value, &optionsDictionary)
                    case _ where key.uppercased().contains("OK"):
                        key = "LocationAlertOk"
                        updateConfiguration(key, value, &optionsDictionary)
                    case _ where key.uppercased().contains("LOCATION_CLIENT_PERMISSION_CANCEL"):
                        key = "LocationAlertCancel"
                        updateConfiguration(key, value, &optionsDictionary)
                    case _ where key.uppercased().contains("LOCATION_CLIENT_PERMISSION_WHENINUSE"):
                        key = "LocationWhenInUseAlert"
                        updateConfiguration(key, value, &alertsDictionary)
                    case _ where key.uppercased().contains("LOCATION_CLIENT_PERMISSION_ALWAYS"):
                        key = "LocationAlwaysAlert"
                        updateConfiguration(key, value, &alertsDictionary)
                    case _ where key.uppercased().contains("LOCATION_CLIENT_PERMISSION_UPGRADE_WHENINUSE_ALWAYS"):
                        key = "LocationUpgradeWhenInUseAlwaysAlert"
                        updateConfiguration(key, value, &alertsDictionary)
                    default: ()
                    }
                }
            }
        }
    }

    // Body ====================================================================
    // Permission / alerts messages.
    var alertsDictionary = NamedMessageCollection()
    // Allow, Deny, OK, Cancel, etc. messages.
    var optionsDictionary = NamedMessageCollection()

    findServices(folderPath: coreLocationPath,
                 alertsDictionary: &alertsDictionary,
                 optionsDictionary: &optionsDictionary)

    // Generate source code:
    write(toFile: "LocationAlerts") { (writer) in
        writer.append(line:"// swiftlint:disable variable_name trailing_comma")
        writer.append(line: "/// Represents possible location service messages and label values on buttons.")
        writer.append(line: "")
        writer.append(line: "import XCTest")

        let createLocationAlertOptions: (NamedMessageCollection) -> Void = { dictionary in
            for item in dictionary {
                let messagesKey: String
                switch item.key {
                case "LocationAlertAllow": messagesKey = "allow"
                case "LocationAlertDeny": messagesKey = "deny"
                case "LocationAlertOk": messagesKey = "ok"
                case "LocationAlertCancel": messagesKey = "cancel"
                default: preconditionFailure("Not supported alert message key.")
                }

                writer.append(line: "")
                writer.append(line: "extension \(item.key) {")
                writer.beginIndent()
                writer.append(line: "public static var \(messagesKey): [String] {")
                writer.beginIndent()
                writer.append(line: "return [")
                writer.beginIndent()
                item.value.forEach({ writer.append(line: "\"\($0)\",") })
                writer.finishIndent()
                writer.append(line: "]")
                writer.finishIndent()
                writer.append(line: "}")
                writer.finishIndent()
                writer.append(line: "}")
            }
        }

        let createLocationAlerts: (NamedMessageCollection) -> Void = { dictionary in
            for item in dictionary {
                writer.append(line: "")
                writer.append(line: "public struct \(item.key): SystemAlert, LocationAlertAllow, LocationAlertDeny {")
                writer.beginIndent()
                writer.append(line: "public static let messages = [")
                writer.beginIndent()
                item.value.forEach({ writer.append(line: "\"\($0)\",") })
                writer.finishIndent()
                writer.append(line: "]")
                writer.finishIndent()
                writer.beginIndent()
                writer.append(line: "public var alert: XCUIElement")
                writer.finishIndent()
                writer.append(line: "")
                writer.beginIndent()
                writer.append(line: "public init?(element: XCUIElement) {")
                writer.beginIndent()
                writer.append(line: "guard let _ = element.staticTexts.elements(withLabelsLike: type(of: self).messages).first else {")
                writer.beginIndent()
                writer.append(line: "return nil")
                writer.finishIndent()
                writer.append(line: "}")
                writer.append(line: "")
                writer.append(line: "self.alert = element")
                writer.finishIndent()
                writer.append(line: "}")
                writer.finishIndent()
                writer.append(line: "}")
            }
        }

        // Creates structure for system alerts:
        createLocationAlertOptions(optionsDictionary)
        // Creates structure for system services:
        createLocationAlerts(alertsDictionary)
    }
}

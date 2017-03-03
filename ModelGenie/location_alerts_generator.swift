import Foundation

// swiftlint:disable:next function_body_length
func generateLocationAlerts() {
    let coreLocationPath = Configuration.developerDirectory + "/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/CoreLocation.framework"

    /// Iterates recursively throught directory content
    func findServices(alertsDictionary: inout NamedMessageCollection, optionsDictionary: inout NamedMessageCollection) {
        readStringsRecursively(fileName: "locationd.strings", in: coreLocationPath) { _, _, content in
            for configuration in content {
                var key = configuration.key
                let value = configuration.value.normalizedForLikeExpression

                switch key {
                case "LOCATION_CLIENT_PERMISSION_OK":
                    key = "LocationAlertAllow"
                    update(namedMessageCollection: &optionsDictionary, key: key, value: value)
                case "DONT_ALLOW":
                    key = "LocationAlertDeny"
                    update(namedMessageCollection: &optionsDictionary, key: key, value: value)
                case "OK":
                    key = "LocationAlertOk"
                    update(namedMessageCollection: &optionsDictionary, key: key, value: value)
                case "LOCATION_CLIENT_PERMISSION_CANCEL":
                    key = "LocationAlertCancel"
                    update(namedMessageCollection: &optionsDictionary, key: key, value: value)
                case "LOCATION_CLIENT_PERMISSION_WHENINUSE":
                    key = "LocationWhenInUseAlert"
                    update(namedMessageCollection: &alertsDictionary, key: key, value: value)
                case "LOCATION_CLIENT_PERMISSION_ALWAYS":
                    key = "LocationAlwaysAlert"
                    update(namedMessageCollection: &alertsDictionary, key: key, value: value)
                case "LOCATION_CLIENT_PERMISSION_UPGRADE_WHENINUSE_ALWAYS":
                    key = "LocationUpgradeWhenInUseAlwaysAlert"
                    update(namedMessageCollection: &alertsDictionary, key: key, value: value)
                default: ()
                }
            }
        }
    }

    // Body ====================================================================
    // Permission / alerts messages.
    var alertsDictionary = NamedMessageCollection()
    // Allow, Deny, OK, Cancel, etc. messages.
    var optionsDictionary = NamedMessageCollection()

    findServices(alertsDictionary: &alertsDictionary,
                 optionsDictionary: &optionsDictionary)

    // Generate source code:
    write(toFile: "LocationAlerts") { (writer) in
        writer.append(line: sharedSwiftLintOptions)
        writer.append(line: "/// Represents possible location service messages and label values on buttons.")
        writer.append(line: "")
        writer.append(line: "import XCTest")

        let createAlertOptions: (NamedMessageCollection) -> Void = { dictionary in
            for item in dictionary.sorted(by: { $0.0.key < $0.1.key }) {
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
                writer.append(line: "")
                writer.append(line: "/// Represents all possible \"\(messagesKey)\" buttons in location service messages.")
                writer.append(line: "public static var \(messagesKey): [String] {")
                writer.beginIndent()
                writer.append(line: "return [")
                writer.beginIndent()
                item.value.sorted().forEach({ writer.append(line: "\"\($0)\",") })
                writer.finishIndent()
                writer.append(line: "]")
                writer.finishIndent()
                writer.append(line: "}")
                writer.finishIndent()
                writer.append(line: "}")
            }
        }

        let createAlerts: (NamedMessageCollection) -> Void = { dictionary in
            for item in dictionary.sorted(by: { $0.0.key < $0.1.key }) {
                let protocols: String
                switch item.key {
                case "LocationUpgradeWhenInUseAlwaysAlert": protocols = "LocationAlertAllow, LocationAlertCancel"
                default: protocols = "LocationAlertAllow, LocationAlertDeny"
                }

                writer.append(line: "")
                writer.append(line: "/// Represents \(item.key) service alert.")
                writer.append(line: "public struct \(item.key): SystemAlert, \(protocols) {")
                writer.beginIndent()
                writer.append(line: "")
                writer.append(line: "/// Represents all possible messages in \(item.key) service alert.")
                writer.append(line: "public static let messages = [")
                writer.beginIndent()
                item.value.sorted().forEach({ writer.append(line: "\"\($0)\",") })
                writer.finishIndent()
                writer.append(line: "]")
                writer.finishIndent()
                writer.beginIndent()
                writer.append(line: "")
                writer.append(line: "/// System service alert element.")
                writer.append(line: "public var alert: XCUIElement")
                writer.finishIndent()
                writer.append(line: "")
                writer.beginIndent()
                writer.append(line: "/// Initialize \(item.key) with alert element.")
                writer.append(line: "///")
                writer.append(line: "/// - Parameter element: An alert element.")
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

        // Creates structure for options:
        createAlertOptions(optionsDictionary)
        // Creates structure for alerts:
        createAlerts(alertsDictionary)
    }
}

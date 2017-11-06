import Foundation

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable:next function_body_length
func generateLocationAlerts() {
    let coreLocationPath = Configuration.developerDirectory + "/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/System/Library/Frameworks/CoreLocation.framework"

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
                case "LOCATION_CLIENT_PERMISSION_ALWAYS_BUTTON":
                    key = "LocationAlwaysAlertAllow"
                    update(namedMessageCollection: &optionsDictionary, key: key, value: value)
                case "LOCATION_CLIENT_PERMISSION_WHENINUSE_BUTTON":
                    key = "LocationAlwaysAlertAllowWhenInUseOnly"
                    update(namedMessageCollection: &optionsDictionary, key: key, value: value)
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

    // Generate JSON files.
    writeToJson(collection: alertsDictionary, foriOS: Configuration.iOSVersion)
    writeToJson(collection: optionsDictionary, foriOS: Configuration.iOSVersion)

    // Generate source code:
    write(toFile: "LocationAlerts") { (writer) in
        writer.append(line: sharedSwiftLintOptions)
        writer.append(line: "/// Represents possible location service messages and label values on buttons.")
        writer.append(line: "")
        writer.append(line: "import XCTest")
        writer.append(line: "#if os(iOS)")

        let createAlertOptions: (NamedMessageCollection) -> Void = { dictionary in
            for item in dictionary.sorted(by: { $0.key < $1.key }) {
                let messagesKey: String
                switch item.key {
                case "LocationAlertAllow": messagesKey = "allow"
                case "LocationAlertDeny": messagesKey = "deny"
                case "LocationAlertOk": messagesKey = "ok"
                case "LocationAlertCancel": messagesKey = "cancel"
                case "LocationAlwaysAlertAllow": messagesKey = "allow"
                case "LocationAlwaysAlertAllowWhenInUseOnly": messagesKey = "cancel"
                default: preconditionFailure("Not supported alert message key.")
                }

                writer.append(line: "")
                writer.append(line: "extension \(item.key) {")
                writer.beginIndent()
                writer.append(line: "")
                writer.append(line: "/// Represents all possible \"\(messagesKey)\" buttons in location service messages.")
                writer.append(line: "public static var \(messagesKey): [String] {")
                writer.beginIndent()
                writer.append(line: "return readMessages(from: \"\(item.key)\")")
                writer.finishIndent()
                writer.append(line: "}")
                writer.finishIndent()
                writer.append(line: "}")
            }
        }

        let createAlerts: (NamedMessageCollection) -> Void = { dictionary in
            for item in dictionary.sorted(by: { $0.key < $1.key }) {
                let protocols: String
                switch item.key {
                case "LocationUpgradeWhenInUseAlwaysAlert": protocols = "LocationAlwaysAlertAllow, LocationAlwaysAlertAllowWhenInUseOnly"
                case "LocationAlwaysAlert": protocols = "LocationAlwaysAlertAllow, LocationAlwaysAlertAllowWhenInUseOnly, LocationAlertDeny"
                default: protocols = "LocationAlertAllow, LocationAlertDeny"
                }

                writer.append(line: "")
                writer.append(line: "/// Represents `\(item.key)` service alert.")
                writer.append(line: "///")
                writer.append(line: "/// System alert supposed to be used in the handler of the `XCTestCase.addUIInterruptionMonitor(withDescription:handler:)` method.")
                writer.append(line: "///")
                writer.append(line: "/// **Example:**")
                writer.append(line: "///")
                writer.append(line: "/// ```swift")
                writer.append(line: "/// let token = addUIInterruptionMonitor(withDescription: \"Alert\") { (alert) -> Bool in")
                writer.append(line: "///     guard let alert = \(item.key)(element: alert) else {")
                writer.append(line: "///         XCTFail(\"Cannot create \(item.key) object\")")
                writer.append(line: "///         return false")
                writer.append(line: "///     }")
                writer.append(line: "///")
                writer.append(line: "///     alert.allowElement.tap()")
                writer.append(line: "///     return true")
                writer.append(line: "/// }")
                writer.append(line: "///")
                writer.append(line: "/// mainPage.goToPermissionsPageMenu()")
                writer.append(line: "/// // Interruption won't happen without some kind of action.")
                writer.append(line: "/// app.tap()")
                writer.append(line: "/// removeUIInterruptionMonitor(token)")
                writer.append(line: "/// ```")
                writer.append(line: "///")
                writer.append(line: "/// - note:")
                writer.append(line: "/// Handlers should return `true` if they handled the UI, `false` if they did not.")
                writer.append(line: "public struct \(item.key): SystemAlert, \(protocols) {")
                writer.beginIndent()
                writer.append(line: "")
                writer.append(line: "/// Represents all possible messages in `\(item.key)` service alert.")
                writer.append(line: "public static let messages = readMessages()")
                writer.finishIndent()
                writer.beginIndent()
                writer.append(line: "")
                writer.append(line: "/// System service alert element.")
                writer.append(line: "public var alert: XCUIElement")
                writer.finishIndent()
                writer.append(line: "")
                writer.beginIndent()
                writer.append(line: "/// Initialize `\(item.key)` with alert element.")
                writer.append(line: "///")
                writer.append(line: "/// - Parameter element: An alert element.")
                writer.append(line: "public init?(element: XCUIElement) {")
                writer.beginIndent()
                writer.append(line: "guard element.staticTexts.elements(withLabelsLike: type(of: self).messages).first != nil else {")
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

        writer.append(line: "#endif")
    }
}

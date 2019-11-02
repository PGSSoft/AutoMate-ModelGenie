import Foundation

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable:next function_body_length
func generateLocationAlerts() {
    let coreLocationPath = Configuration.developerDirectory + "/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/System/Library/Frameworks/CoreLocation.framework"

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
                case "LOCATION_CLIENT_PERMISSION_ONETIME_BUTTON":
                    key = "LocationWhenInUseAlertAllowOneTime"
                    update(namedMessageCollection: &optionsDictionary, key: key, value: value)
                case "LOCATION_CLIENT_PERMISSION_WHENINUSE_BUTTON":
                    key = "LocationWhenInUseAlertAllow"
                    update(namedMessageCollection: &optionsDictionary, key: key, value: value)
                case "LOCATION_CLIENT_PERMISSION_WHENINUSE_ONLY_BUTTON":
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
        writer.append(
"""
\(sharedSwiftLintOptions)
/// Represents possible location service messages and label values on buttons.

import XCTest
#if os(iOS)
"""
        )

        let createAlertOptions: (NamedMessageCollection) -> Void = { dictionary in
            for item in dictionary.sorted(by: { $0.key < $1.key }) {
                let messagesKey: String
                switch item.key {
                case "LocationAlertAllow": messagesKey = "allow"
                case "LocationAlertDeny": messagesKey = "deny"
                case "LocationAlertOk": messagesKey = "ok"
                case "LocationAlertCancel": messagesKey = "cancel"
                case "LocationAlwaysAlertAllow": messagesKey = "allow"
                case "LocationWhenInUseAlertAllow": messagesKey = "allow"
                case "LocationWhenInUseAlertAllowOneTime": messagesKey = "allowOneTime"
                case "LocationAlwaysAlertAllowWhenInUseOnly": messagesKey = "whenInUseOnly"
                default: preconditionFailure("Not supported alert message key.")
                }

                writer.append(
"""


extension \(item.key) {

    /// Represents all possible \"\(messagesKey)\" buttons in location service messages.
    public static var \(messagesKey): [String] {
        return readMessages(from: \"\(item.key)\")
    }
}
"""
                )
            }
        }

        let createAlerts: (NamedMessageCollection) -> Void = { dictionary in
            for item in dictionary.sorted(by: { $0.key < $1.key }) {
                let protocols: String
                switch item.key {
                case "LocationUpgradeWhenInUseAlwaysAlert": protocols = "LocationAlwaysAlertAllow, LocationAlwaysAlertAllowWhenInUseOnly"
                case "LocationAlwaysAlert": protocols = "LocationAlwaysAlertAllow, LocationAlwaysAlertAllowWhenInUseOnly, LocationAlertDeny"
                case "LocationWhenInUseAlert": protocols = "LocationWhenInUseAlertAllow, LocationWhenInUseAlertAllowOneTime, LocationAlertDeny"
                default: protocols = "LocationAlertAllow, LocationAlertDeny"
                }

                writer.append(
"""

/// Represents `\(item.key)` service alert.
///
/// System alert supposed to be used in the handler of the `XCTestCase.addUIInterruptionMonitor(withDescription:handler:)` method.
///
/// **Example:**
///
/// ```swift
/// let token = addUIInterruptionMonitor(withDescription: \"Alert\") { (alert) -> Bool in
///     guard let alert = \(item.key)(element: alert) else {
///         XCTFail(\"Cannot create \(item.key) object\")
///         return false
///     }
///
///     alert.allowElement.tap()
///     return true
/// }
///
/// mainPage.goToPermissionsPageMenu()
/// // Interruption won't happen without some kind of action.
/// app.tap()
/// removeUIInterruptionMonitor(token)
/// ```
///
/// - note:
/// Handlers should return `true` if they handled the UI, `false` if they did not.
public struct \(item.key): SystemAlert, \(protocols) {

    /// Represents all possible messages in `\(item.key)` service alert.
    public static let messages = readMessages()

    /// System service alert element.
    public var alert: XCUIElement

    /// Initialize `\(item.key)` with alert element.
    ///
    /// - Parameter element: An alert element.
    public init?(element: XCUIElement) {
        guard element.staticTexts.elements(withLabelsLike: type(of: self).messages).first != nil else {
            return nil
        }

        self.alert = element
    }
}

"""
                )
            }
        }

        // Creates structure for options:
        createAlertOptions(optionsDictionary)
        // Creates structure for alerts:
        createAlerts(alertsDictionary)

        writer.append(line: "#endif")
    }
}

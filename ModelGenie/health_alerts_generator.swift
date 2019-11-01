//
//  health_alerts_generator.swift
//  ModelGenie
//
//  Created by Bartosz Janda on 15.02.2017.
//  Copyright © 2017 PGS Software S.A. All rights reserved.
//

import Foundation

// swiftlint:disable:next function_body_length
func generateHealthAlerts() {
    let healthKitPath = Configuration.developerDirectory + "/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/System/Library/PrivateFrameworks/HealthUI.framework"

    /// Iterates recursively throught directory content
    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func findServices(viewsDictionary: inout NamedMessageCollection, alertsDictionary: inout NamedMessageCollection, optionsDictionary: inout NamedMessageCollection) {
        readStringsRecursively(fileName: "HealthUI-Localizable.strings", in: healthKitPath) { _, _, content in
            for configuration in content {
                var key = configuration.key
                let value = configuration.value.normalizedForLikeExpression

                switch key {
                case "AUTHORIZATION_PROMPT_ALLOW":
                    key = "HealthAlertAllow"
                    update(namedMessageCollection: &optionsDictionary, key: key, value: value)
                case "AUTHORIZATION_PROMPT_DONT_ALLOW":
                    key = "HealthAlertDeny"
                    update(namedMessageCollection: &optionsDictionary, key: key, value: value)
                case "ENABLE_ALL_CATEGORIES":
                    key = "HealthAlertTurnOnAll"
                    update(namedMessageCollection: &optionsDictionary, key: key, value: value)
                case "DISABLE_ALL_CATEGORIES":
                    key = "HealthAlertTurnOffAll"
                    update(namedMessageCollection: &optionsDictionary, key: key, value: value)
                case "AUTHORIZATION_DONT_ALLOW_ALERT_OK":
                    key = "HealthAlertOk"
                    update(namedMessageCollection: &optionsDictionary, key: key, value: value)
                case "%@_WOULD_LIKE_TO_ACCESS_YOUR_HEALTH_DATA":
                    key = "HealthPermissionPage"
                    update(namedMessageCollection: &viewsDictionary, key: key, value: value)
                case "AUTHORIZATION_DONT_ALLOW_ALERT_TITLE":
                    key = "HealthAuthorizationDontAllowAlert"
                    update(namedMessageCollection: &alertsDictionary, key: key, value: value)
                default: ()
                }
            }
        }
    }

    // Body ====================================================================
    // Permission messages.
    var viewsDictionary = NamedMessageCollection()
    // Alerts messages.
    var alertsDictionary = NamedMessageCollection()
    // Allow, Deny, OK, Cancel, etc. messages.
    var optionsDictionary = NamedMessageCollection()

    findServices(viewsDictionary: &viewsDictionary,
        alertsDictionary: &alertsDictionary,
        optionsDictionary: &optionsDictionary)

    // Generate JSON files.
    writeToJson(collection: viewsDictionary, foriOS: Configuration.iOSVersion)
    writeToJson(collection: alertsDictionary, foriOS: Configuration.iOSVersion)
    writeToJson(collection: optionsDictionary, foriOS: Configuration.iOSVersion)

    // Generate source code:
    write(toFile: "HealthAlerts") { (writer) in
        writer.append(
"""
\(sharedSwiftLintOptions)
/// Represents possible health service messages and label values on buttons.

import XCTest
#if os(iOS)
"""
        )

        let createAlertOptions: (NamedMessageCollection) -> Void = { dictionary in
            for item in dictionary.sorted(by: { $0.key < $1.key }) {
                let messagesKey: String
                switch item.key {
                case "HealthAlertAllow": messagesKey = "allow"
                case "HealthAlertDeny": messagesKey = "deny"
                case "HealthAlertTurnOnAll": messagesKey = "turnOnAll"
                case "HealthAlertTurnOffAll": messagesKey = "turnOffAll"
                case "HealthAlertOk": messagesKey = "ok"
                default: preconditionFailure("Not supported alert message key.")
                }

                writer.append(
"""


extension \(item.key) {

    /// Represents all possible \"\(messagesKey)\" buttons in HealthKit permission view.
    public static var \(messagesKey): [String] {
        return readMessages(from: \"\(item.key)\")
    }
}
"""
                )
            }
        }

        let createViews: (NamedMessageCollection) -> Void = { dictionary in
            for item in dictionary.sorted(by: { $0.key < $1.key }) {
                writer.append(
"""


extension \(item.key) {

    /// Represents all possible messages in HealthKit permission view.
    public static var messages: [String] {
        return readMessages(from: \"\(item.key)\")
    }
}
"""
                )
            }
        }

        let createAlerts: (NamedMessageCollection) -> Void = { dictionary in
            for item in dictionary.sorted(by: { $0.key < $1.key }) {
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
/// - warning:
/// The alert seems to be visible in view hierarchy and work without an \"interruption monitor dance\".
/// Check working example here: [AutoMateExample `PermissionsTests -testHealthKitAlert`](https://github.com/PGSSoft/AutoMate/blob/master/AutoMateExample/AutoMateExampleUITests/PermissionsTests.swift)
public struct \(item.key): SystemAlert, HealthAlertOk {

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
        // Create classes for options:
        createViews(viewsDictionary)
        // Creates structure for alerts:
        createAlerts(alertsDictionary)

        writer.append(line: "#endif")
    }
}

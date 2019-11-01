//
//  service_request_alerts_generator.swift
//  ModelGenie
//
//  Created by Ewelina Cyło on 20/01/2017.
//  Copyright © 2017 PGS Software S.A. All rights reserved.
//

import Foundation

// swiftlint:disable:next function_body_length
func generateServiceRequestAlerts() {
    let serviceAlertsPath = Configuration.developerDirectory + "/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/System/Library/PrivateFrameworks/TCC.framework"

    /// Iterates recursively throught directory content
    func findServices(servicesDictionary: inout NamedMessageCollection, optionsDictionary: inout NamedMessageCollection) {
        readStringsRecursively(fileName: "Localizable.strings", in: serviceAlertsPath) { _, _, content in
            for configuration in content {
                // Keys are constructed in following manner:
                // - REQUEST_ACCESS_SERVICE_kTCCService[ServiceName]
                // - REQUEST_ACCESS_INFO_SERVICE_kTCCService[ServiceName]
                // - REQUEST_ACCESS_[Allow/Deny]

                // Removing prefix for system alerts:
                var key = configuration.key
                    .replacingOccurrences(of: "REQUEST_ACCESS_SERVICE_kTCCService", with: "")
                    .replacingOccurrences(of: "REQUEST_ACCESS_INFO_SERVICE_kTCCService", with: "")
                    .replacingOccurrences(of: "REQUEST_ACCESS_", with: "")
                    .replacingOccurrences(of: "REQUEST_DEFAULT_PURPOSE_STRING_SERVICE_kTCCService", with: "DefaultPurpose")
                let value = configuration.value.normalizedForLikeExpression

                switch key {
                case _ where key.uppercased().contains("ALLOW"):
                    key = "SystemAlertAllow"
                    update(namedMessageCollection: &optionsDictionary, key: key, value: value)
                case _ where key.uppercased().contains("DENY"):
                    key = "SystemAlertDeny"
                    update(namedMessageCollection: &optionsDictionary, key: key, value: value)
                default:
                    key = "\(key)Alert"
                    update(namedMessageCollection: &servicesDictionary, key: key, value: value)
                }
            }
        }
    }

    // Body ====================================================================
    // Speech Recognition, Siri, Reminders, Photos, Camera, etc. messages.
    var alertsDictionary = NamedMessageCollection()
    // Allow and Deny messages.
    var optionsDictionary = NamedMessageCollection()

    findServices(servicesDictionary: &alertsDictionary,
                 optionsDictionary: &optionsDictionary)

    // Generate JSON files.
    writeToJson(collection: alertsDictionary, foriOS: Configuration.iOSVersion)
    writeToJson(collection: optionsDictionary, foriOS: Configuration.iOSVersion)

    // Generate source code:
    write(toFile: "ServiceRequestAlerts") { (writer) in
        writer.append(
"""
\(sharedSwiftLintOptions)
/// Represents possible system service messages and label values on buttons.

import XCTest
#if os(iOS)

"""
        )

        let createAlertOptions: (NamedMessageCollection) -> Void = { dictionary in
            for item in dictionary.sorted(by: { $0.key < $1.key }) {
                let messagesKey: String
                switch item.key {
                case "SystemAlertAllow": messagesKey = "allow"
                case "SystemAlertDeny": messagesKey = "deny"
                default: preconditionFailure("Not supported alert message key.")
                }

                writer.append(
"""

extension \(item.key) {

    /// Represents all possible \"\(messagesKey)\" buttons in system service messages.
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
///     alert.denyElement.tap()
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
public struct \(item.key): SystemAlert, SystemAlertAllow, SystemAlertDeny {

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

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
    let serviceAlertsPath = Configuration.developerDirectory + "/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/System/Library/PrivateFrameworks/TCC.framework"

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
        writer.append(line: sharedSwiftLintOptions)
        writer.append(line: "/// Represents possible system service messages and label values on buttons.")
        writer.append(line: "")
        writer.append(line: "import XCTest")
        writer.append(line: "#if os(iOS)")

        let createAlertOptions: (NamedMessageCollection) -> Void = { dictionary in
            for item in dictionary.sorted(by: { $0.key < $1.key }) {
                let messagesKey: String
                switch item.key {
                case "SystemAlertAllow": messagesKey = "allow"
                case "SystemAlertDeny": messagesKey = "deny"
                default: preconditionFailure("Not supported alert message key.")
                }

                writer.append(line: "")
                writer.append(line: "extension \(item.key) {")
                writer.beginIndent()
                writer.append(line: "")
                writer.append(line: "/// Represents all possible \"\(messagesKey)\" buttons in system service messages.")
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
                writer.append(line: "///     alert.denyElement.tap()")
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
                writer.append(line: "public struct \(item.key): SystemAlert, SystemAlertAllow, SystemAlertDeny {")
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

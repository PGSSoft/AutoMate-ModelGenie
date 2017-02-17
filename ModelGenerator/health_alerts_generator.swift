//
//  health_alerts_generator.swift
//  ModelGenerator
//
//  Created by Bartosz Janda on 15.02.2017.
//  Copyright © 2017 PGS Software S.A. All rights reserved.
//

import Foundation

// swiftlint:disable:next function_body_length
func generateHealthAlerts() {
    let healthKitPath = Configuration.developerDirectory + "/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/PrivateFrameworks/HealthUI.framework"

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
                    key = "HealthPermissionView"
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

    // Generate source code:
    write(toFile: "HealthAlerts") { (writer) in
        writer.append(line: sharedSwiftLintOptions)
        writer.append(line: "/// Represents possible health service messages and label values on buttons.")
        writer.append(line: "")
        writer.append(line: "import XCTest")

        let createAlertOptions: (NamedMessageCollection) -> Void = { dictionary in
            for item in dictionary.sorted(by: { $0.0.key < $0.1.key }) {
                let messagesKey: String
                switch item.key {
                case "HealthAlertAllow": messagesKey = "allow"
                case "HealthAlertDeny": messagesKey = "deny"
                case "HealthAlertTurnOnAll": messagesKey = "turnOnAll"
                case "HealthAlertTurnOffAll": messagesKey = "turnOffAll"
                case "HealthAlertOk": messagesKey = "ok"
                default: preconditionFailure("Not supported alert message key.")
                }

                writer.append(line: "")
                writer.append(line: "extension \(item.key) {")
                writer.beginIndent()
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

        let createViews: (NamedMessageCollection) -> Void = { dictionary in
            for item in dictionary.sorted(by: { $0.0.key < $0.1.key }) {
                writer.append(line: "")
                writer.append(line: "public extension \(item.key) {")
                writer.beginIndent()
                writer.append(line: "public static let messages = [")
                writer.beginIndent()
                item.value.sorted().forEach({ writer.append(line: "\"\($0)\",") })
                writer.finishIndent()
                writer.append(line: "]")
                writer.finishIndent()
                writer.append(line: "}")
            }
        }

        let createAlerts: (NamedMessageCollection) -> Void = { dictionary in
            for item in dictionary.sorted(by: { $0.0.key < $0.1.key }) {
                writer.append(line: "")
                writer.append(line: "public struct \(item.key): SystemAlert, HealthAlertOk {")
                writer.beginIndent()
                writer.append(line: "public static let messages = [")
                writer.beginIndent()
                item.value.sorted().forEach({ writer.append(line: "\"\($0)\",") })
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

        // Creates structure for options:
        createAlertOptions(optionsDictionary)
        // Create classes for options:
        createViews(viewsDictionary)
        // Creates structure for alerts:
        createAlerts(alertsDictionary)
    }
}

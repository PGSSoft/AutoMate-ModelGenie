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
    let serviceAlertsPath = Configuration.developerDirectory + "/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/PrivateFrameworks/TCC.framework"

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

    // Generate source code:
    write(toFile: "ServiceRequestAlerts") { (writer) in
        writer.append(line: sharedSwiftLintOptions)
        writer.append(line: "/// Represents possible system service messages and label values on buttons.")
        writer.append(line: "")
        writer.append(line: "import XCTest")

        let createAlertOptions: (NamedMessageCollection) -> Void = { dictionary in
            for item in dictionary.sorted(by: { $0.0.key < $0.1.key }) {
                writer.append(line: "")
                writer.append(line: "extension \(item.key) {")
                writer.beginIndent()
                writer.append(line: "public static var \(item.key.lowercased().contains("allow") ? "allow" : "deny"): [String] {")
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
                writer.append(line: "")
                writer.append(line: "public struct \(item.key): SystemAlert, SystemAlertAllow, SystemAlertDeny {")
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
        // Creates structure for alerts:
        createAlerts(alertsDictionary)
    }
}

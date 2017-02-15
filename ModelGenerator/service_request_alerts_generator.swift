//
//  service_request_alerts_generator.swift
//  ModelGenerator
//
//  Created by Ewelina Cyło on 20/01/2017.
//  Copyright © 2017 PGS Software S.A. All rights reserved.
//

import Foundation

// swiftlint:disable:next function_body_length
func generateServiceRequestAlerts() {
    let serviceAlertsPath = Configuration.developerDirectory + "/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/PrivateFrameworks/TCC.framework"

    typealias MessageCollection = Set<String>
    typealias NamedMessageCollection = [String: MessageCollection]

    /// Iterates recursively throught directory content
    func findServices(folderPath: String, servicesDictionary: inout NamedMessageCollection, optionsDictionary: inout NamedMessageCollection) {
        let serviceAlertsConfigurationFileName = "Localizable.strings"
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
                findServices(folderPath: path, servicesDictionary: &servicesDictionary, optionsDictionary: &optionsDictionary)
            } else if element == serviceAlertsConfigurationFileName {
                for configuration in readStrings(fromPath: path) {
                    // Keys are constructed in following manner:
                    // - REQUEST_ACCESS_SERVICE_kTCCService[ServiceName]
                    // - REQUEST_ACCESS_INFO_SERVICE_kTCCService[ServiceName]
                    // - REQUEST_ACCESS_[Allow/Deny]

                    // Removing prefix for system alerts:
                    var key = configuration.key
                        .replacingOccurrences(of: "REQUEST_ACCESS_SERVICE_kTCCService", with: "")
                        .replacingOccurrences(of: "REQUEST_ACCESS_INFO_SERVICE_kTCCService", with: "")
                        .replacingOccurrences(of: "REQUEST_ACCESS_", with: "")

                    let value = configuration.value
                        .replacingOccurrences(of: "\"", with: "\\\"")
                        .replacingOccurrences(of: "%@", with: "*")

                    let updateConfiguration: ((String, String, inout NamedMessageCollection) -> Void) = { (key, value, dictionary) in
                        var collection = dictionary[key] ?? MessageCollection()
                        collection.insert(value)
                        dictionary[key] = collection
                    }

                    switch key {
                    case _ where key.uppercased().contains("ALLOW"):
                        key = "SystemAlertAllow"
                        updateConfiguration(key, value, &optionsDictionary)
                    case _ where key.uppercased().contains("DENY"):
                        key = "SystemAlertDeny"
                        updateConfiguration(key, value, &optionsDictionary)
                    default:
                        key = "\(key)Alert"
                        updateConfiguration(key, value, &servicesDictionary)
                    }
                }
            }
        }
    }

    // Body ====================================================================
    // Speech Recognition, Siri, Reminders, Photos, Camera, etc. messages.
    var servicesDictionary = NamedMessageCollection()
    // Allow and Deny messages.
    var optionsDictionary = NamedMessageCollection()

    findServices(folderPath: serviceAlertsPath,
                 servicesDictionary: &servicesDictionary,
                 optionsDictionary: &optionsDictionary)

    // Generate source code:
    write(toFile: "ServiceRequestAlerts") { (writer) in
        writer.append(line:"// swiftlint:disable variable_name trailing_comma")
        writer.append(line: "/// Represents possible system service messages and label values on buttons.")
        writer.append(line: "")
        writer.append(line: "import XCTest")

        let createSystemAlertOptions: (NamedMessageCollection) -> Void = { dictionary in
            for item in dictionary {
                writer.append(line: "")
                writer.append(line: "extension \(item.key) {")
                writer.beginIndent()
                writer.append(line: "public static var \(item.key.lowercased().contains("allow") ? "allow" : "deny"): [String] {")
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

        let createSystemServices: (NamedMessageCollection) -> Void = { dictionary in
            for item in dictionary {
                writer.append(line: "")
                writer.append(line: "public struct \(item.key): SystemAlert, SystemAlertAllow, SystemAlertDeny {")
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
        createSystemAlertOptions(optionsDictionary)
        // Creates structure for system services:
        createSystemServices(servicesDictionary)
    }
}

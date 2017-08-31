//
//  configuration.swift
//  ModelGenie
//
//  Created by Ewelina Cyło on 08/02/2017.
//  Copyright © 2017 PGS Software S.A. All rights reserved.
//

import Foundation

struct Configuration {
    static let developerDirectory: String = {
        return ProcessInfo.processInfo.environment["DEVELOPER_DIR"]!
    }()

    static let developerDirectoryUrl: URL = {
        return URL(fileURLWithPath: developerDirectory, isDirectory: true)
    }()

    static let sourceDirectory: String = {
        return ProcessInfo.processInfo.environment["SRCROOT"]!
    }()

    static let sourceDirectoryUrl: URL = {
        return URL(fileURLWithPath: sourceDirectory, isDirectory: true)
    }()

    static let outputDirectory = "GeneratedModels"
    static let iOSVersion = "11.0"
}

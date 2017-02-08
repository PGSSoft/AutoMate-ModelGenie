//
//  configuration.swift
//  ModelGenerator
//
//  Created by Ewelina Cyło on 08/02/2017.
//  Copyright © 2017 PGS Software S.A. All rights reserved.
//

import Foundation

struct Configuration {
    static let developerDirectory: String = {
        return ProcessInfo.processInfo.environment["DEVELOPER_DIR"]!
    }()
}

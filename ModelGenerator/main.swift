//
//  main.swift
//  ModelGenerator
//
//  Created by Pawel Szot on 12/08/16.
//  Copyright © 2016 PSZOT. All rights reserved.
//

import Foundation

let outputDirectory = "GeneratedModels"

generateCountries()
generateKeyboards()
generateLabels()
generateServiceRequestAlerts()
//generateLanguages() // Doesn't work with Xcode 8

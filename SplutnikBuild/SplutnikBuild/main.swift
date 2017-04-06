//
//  main.swift
//  SplutnikBuild
//
//  Created by Michael Wright on 06/04/2017.
//  Copyright © 2017 wrightm@mac.com. All rights reserved.
//

import Foundation

let settingsFilePath = "\(FileManager.default.currentDirectoryPath)/Splutnik.json"

let settings = Settings(filename: settingsFilePath)

if let match = settings.match(sectionName: "Redirects", query: "Hello.abcpq") {
    print("*** [match=\(match.string)]")
}
else {
    print("*** no match")
}

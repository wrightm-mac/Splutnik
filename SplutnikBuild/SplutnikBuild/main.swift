//
//  main.swift
//  SplutnikBuild
//
//  Created by Michael Wright on 06/04/2017.
//  Copyright © 2017 wrightm@mac.com. All rights reserved.
//

import Foundation

//let settingsFilePath = "\(FileManager.default.currentDirectoryPath)/Splutnik.json"
//let settingsFilePath = "\(FileManager.default.homeDirectoryForCurrentUser)Development/Xcode/Splutnik/SplutnikBuild/SplutnikBuild/Splutnik.json"
let settingsFilePath = "/Users/mwright//Development/Xcode/Splutnik/SplutnikBuild/SplutnikBuild/Splutnik.json"
let settings = Settings(filename: settingsFilePath)

if let match = settings.match(sectionName: "Redirects", query: "Hello.abcpq") {
    Console.debug("*** [match=\(match.string)]")
}
else {
    Console.debug("*** no match")
}

//
//  Settings.swift
//  SplutnikBuild
//
//  Created by Michael Wright on 06/04/2017.
//  Copyright © 2017 wrightm@mac.com. All rights reserved.
//

import Foundation


open class Settings {
    
    // MARK:    Fields...
    
    public private(set) var json: Json
    
    
    // MARK:    Configuration...
    
    public let serverName: String
    
    public let serverPort: UInt16
    
    public let maximumConnections: Int
    
    public let documentDirectory: String
    
    
    // MARK:    Initialisers...
    
    public init(filename: String) {
        json = Json(filename: filename)
        
        let serverSettings = json["Server"].dictionary
        serverName = serverSettings["ServerName"].string
        serverPort = UInt16(serverSettings["ServerPort"].int)
        maximumConnections = serverSettings["MaximumConnections"].int
        documentDirectory = serverSettings["DocumentDirectory"].string
    }
    
    
    // MARK:    Methods...
    
    func match(sectionName: String, query: String) -> JsonElement? {
        var result: JsonElement? = nil
        
        for (name, value) in json[sectionName].items {
            do {
                let regex = try NSRegularExpression(pattern: "^\(name)$", options: [])
                if regex.firstMatch(in: query, options: [], range: NSMakeRange(0, query.characters.count)) != nil {
                    result = JsonElement(value)
                    break
                }
            }
            catch {
                print("Settings.match - two problems error")
            }
        }
        
        return result
    }
    
    public func match(query: String) -> SettingsMatch? {
        if let result = match(sectionName: SettingsSection.forwards.rawValue, query: query) {
            return SettingsMatch(section: .forwards, query: query, match: result.string)
        }
        else if let result = match(sectionName: SettingsSection.redirects.rawValue, query: query) {
            return SettingsMatch(section: .redirects, query: query, match: result.string)
        }
        else {
            return nil
        }
    }
}

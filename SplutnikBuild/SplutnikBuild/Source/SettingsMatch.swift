//
//  SettingsMatch.swift
//  SplutnikBuild
//
//  Created by Michael Wright on 06/04/2017.
//  Copyright © 2017 wrightm@mac.com. All rights reserved.
//

import Foundation


/**
 Sections within the *JSON* configuration file.
 */
public enum SettingsSection: String {
    case mime = "MimeType"
    case forwards = "Forwards"
    case redirects = "Redirects"
}


/**
 Represents a match to a configuration setting.
 
 Typically used to represent a server-request path to a forward/redirect.
 */
public class SettingsMatch {
    
    // MARK:    Fields...
    
    public private(set) var section: SettingsSection
    
    public private(set) var query: String
    
    public private(set) var match: String
    
    
    // MARK:    Initialisers...
    
    public init(section: SettingsSection, query: String, match: String) {
        self.section = section
        self.query = query
        self.match = match
    }
}

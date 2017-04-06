//
//  StringExtensions.swift
//  SplutnikBuild
//
//  Created by Michael Wright on 06/04/2017.
//  Copyright © 2017 wrightm@mac.com. All rights reserved.
//

import Foundation


public extension String {
    
    func trim(charactersIn: String) -> String {
        return self.trim(charactersIn: CharacterSet(charactersIn: charactersIn))
    }
    
    func trim(charactersIn: CharacterSet = CharacterSet.whitespacesAndNewlines) -> String {
        return self.trimmingCharacters(in: charactersIn)
    }
}

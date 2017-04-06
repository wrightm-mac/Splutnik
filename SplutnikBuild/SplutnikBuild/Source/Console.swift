//
//  Console.swift
//  SplutnikBuild
//
//  Created by Michael Wright on 06/04/2017.
//  Copyright © 2017 wrightm@mac.com. All rights reserved.
//

import Foundation


open class Console {
    
    // MARK:    Aliases...
    
    public typealias MessageFunc = () -> String
    
    
    // MARK:    Initialisers...
    
    private init() {
    }
    
    
    // MARK:    Methods...
    
    public static func write(prefix: String,  _ message: String) {
        print("\(prefix) \(message)")
    }
    
    public static func debug(_ message: String) {
        write(prefix: "😶", message)
    }
    
    public static func info(_ message: String) {
        write(prefix: "😎", message)
    }
    
    public static func event(_ message: String) {
        write(prefix: "😁", message)
    }
    
    public static func warn(_ message: String) {
        write(prefix: "☹️", message)
    }
    
    public static func error(_ message: String) {
        write(prefix: "💩", message)
    }
}

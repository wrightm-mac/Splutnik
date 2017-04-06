//
//  FileReader.swift
//  SplutnikBuild
//
//  Created by Michael Wright on 06/04/2017.
//  Copyright © 2017 wrightm@mac.com. All rights reserved.
//

import Foundation


open class FileReader {
 
    // MARK:    Fields...
    
    public let basepath: String
    
    
    // MARK:    Initialisers...
    
    public init(basepath: String) {
        self.basepath = basepath
    }
    
    public convenience init() {
        let documentsDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        self.init(basepath: "\(documentsDirectory)/WebServer/")
    }
    
    
    // MARK:    Methods...
    
    open func getContents(document: String) -> Data? {
        let fullpath = "\(basepath)\(document)"
        
        guard FileManager.default.fileExists(atPath: fullpath) else {
            return nil
        }
        
        let url = URL(fileURLWithPath: fullpath)
        
        do {
            let data = try Data(contentsOf: url)
            return data
        }
        catch let ex {
            Console.error("cannot construct url for '\(fullpath)' - exception='\(ex)'")
        }
        
        return nil
    }
}

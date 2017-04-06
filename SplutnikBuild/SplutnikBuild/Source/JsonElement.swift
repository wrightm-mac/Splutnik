//
//  JsonElement.swift
//  SplutnikBuild
//
//  Created by Michael Wright on 06/04/2017.
//  Copyright © 2017 wrightm@mac.com. All rights reserved.
//

import Foundation


open class JsonElement: CustomStringConvertible {
    
    private var object: AnyObject
    
    public init(_ object: AnyObject) {
        self.object = object
    }
    
    public var dictionary: Json {
        return Json(object: object)
    }
    
    public var array: [AnyObject] {
        return object as! [AnyObject]
    }
    
    public var items: [JsonItem] {
        return dictionary.items
    }
    
    public var string: String {
        return String(describing: object)
    }
    
    public var int: Int {
        return object as! Int
    }
    
    public var double: Double {
        return object as! Double
    }
    
    public var description: String {
        return String(describing: object)
    }
}

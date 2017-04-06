//
//  Json.swift
//  SplutnikBuild
//
//  Created by Michael Wright on 06/04/2017.
//  Copyright © 2017 wrightm@mac.com. All rights reserved.
//

import Foundation


public typealias JsonDictionary = [String: AnyObject]

public typealias JsonItem = (key: String, value: AnyObject)


open class Json {
    
    private var dictionary: JsonDictionary
    
    
    public init(object: AnyObject) {
        dictionary = object as! JsonDictionary
    }
    
    public convenience init(data: Data) {
        self.init(object: try! JSONSerialization.jsonObject(with: data) as AnyObject)
    }
    
    public convenience init(filename: String) {
        self.init(data: try! Data(contentsOf: URL(fileURLWithPath: filename)))
    }
    
    
    public subscript(key: String) -> JsonElement {
        return JsonElement(dictionary[key]!)
    }
    
    public var keys: [String] {
        return dictionary.keys.map { $0 }
    }
    
    public var items: [JsonItem] {
        return dictionary.map { ($0.key, $0.value) }
    }
}

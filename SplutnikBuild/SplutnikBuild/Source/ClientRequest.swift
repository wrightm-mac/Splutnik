//
//  ClientRequest.swift
//  SplutnikBuild
//
//  Created by Michael Wright on 06/04/2017.
//  Copyright © 2017 wrightm@mac.com. All rights reserved.
//

import Foundation


public struct ClientRequest {
    
    public enum Method: String {
        case Unknown = "",
        Get = "GET",
        Head = "HEAD",
        Post = "POST",
        Put = "PUT",
        Delete = "DELETE",
        Trace = "TRACE",
        Connect = "CONNECT"
    }

    
    // MARK:    Constants...
    
    public let readBufferSize = 64 * 1024
    
    public let parseParameters = true
    
    public let parseHeaders = true
    
    
    // MARK:    Fields...
    
    var socket: Int32
    
    var method: Method = .Unknown
    
    var uri: String = ""
    
    var paramString: String = ""
    
    var parameters = [String:String]()
    
    var version: String = ""
    
    var headers = [String:String]()
    
    var body: String = ""
    
    
    // MARK:    Initialisers...
    
    init(socket: Int32) {
        self.socket = socket
        
        var lineNumber = 0
        var line = ""
        var isHeaders = true
        var headerName: String? = nil
        
        var buffer = [UInt8](repeating: 0, count: readBufferSize)
        read(socket, &buffer, readBufferSize)
        
        for rawCharacter in buffer
        {
            if rawCharacter == 0 {
                break
            }
            
            let character = Character(UnicodeScalar(rawCharacter))
            switch rawCharacter {
            case 10:
                continue
            case 13:
                if line.characters.count == 0 {
                    isHeaders = false
                }
                else {
                    if isHeaders {
                        if lineNumber == 0 {
                            let chunks = line.characters.split{$0 == " "}.map(String.init)
                            if (chunks.count == 3) {
                                if let method = Method(rawValue: chunks[0]) {
                                    self.method = method
                                }
                                let path = chunks[1]
                                let pathParts = path.components(separatedBy: "?")
                                uri = (pathParts.count > 0) ? pathParts[0] : ""
                                if pathParts.count > 1 {
                                    paramString = pathParts[1]
                                    if parseParameters {
                                        for parameter in paramString.components(separatedBy: "&") {
                                            let parameterParts = parameter.components(separatedBy: "=")
                                            if parameterParts.count == 2 {
                                                parameters[parameterParts[0]] = parameterParts[1]
                                            }
                                            else {
                                                parameters[parameterParts[0]] = ""
                                            }
                                        }
                                    }
                                }
                                version = chunks[2]
                            }
                        }
                        else {
                            if let name = headerName {
                                headers[name] = line.trim()
                            }
                        }
                        
                        headerName = nil
                    }
                    
                    line = ""
                    lineNumber += 1
                }
            default:
                if isHeaders {
                    if (character == ":") && (headerName == nil) {
                        headerName = line
                        line = ""
                    }
                    else {
                        line += String(character)
                    }
                }
                else {
                    body += String(character)
                }
            }
        }
        
        Console.info("request\t[\(method.rawValue)\(uri)]")
        for (name, value) in parameters {
            Console.info("parameter\t[name=\(name)][value=\(value)]")
        }
        for (name, value) in headers {
            Console.info("header\t[name=\(name)][value=\(value)]")
        }
    }
    
    
    // MARK:    Methods...
    
    func getResponse() -> ClientResponse {
        return ClientResponse(request: self)
    }
    
    func debug() {
        print("\(method.rawValue) \(uri) \(version)")
        for key in self.headers.keys {
            print("header [name=\(key)][value=\(headers[key]!)]")
        }
        print("body [\(body)]")
    }
}

//
//  ClientResponse.swift
//  SplutnikBuild
//
//  Created by Michael Wright on 06/04/2017.
//  Copyright © 2017 wrightm@mac.com. All rights reserved.
//

import Foundation


public struct ClientResponse {
    
    public enum ResponseCode: Int {
        case
        OK = 200,
        Redirect = 307,
        NotFound = 404,
        ServerError = 500
        
        var message: String {
            switch self {
            case .OK: return "OK"
            case .Redirect: return "PERMANENT REDIRECT"
            case .NotFound: return "NOT FOUND"
            case .ServerError: return "SERVER ERROR"
            }
        }
    }
    
    
    // MARK:    Constants...
    
    let httpVersion = "HTTP/1.1"
    let lineEnding = "\r\n"
    let rfc7231Date = "EEE, d MMM yyyy HH:mm:ss z"
    
    // Default value of "Content-Type" header...
    let defaultContentTypeHeader = "text/html; charset=utf-8"
    
    
    // MARK:    Fields...
    
    private let dateFormatter: DateFormatter
    
    private let clientRequest: ClientRequest
    var request: ClientRequest {
        return clientRequest
    }
    
    // Headers that are sent as part of a response - note that all responses
    // are sent as 'text/html' - TODO: check for different content-types when
    // sending response (maybe use a mapping in configuration file).
    var headers: [String:String] = [
        "Content-Encoding": "UTF-8",
        //!"Server": "\(serverName)/\(serverVersion) (macOS))",
        "Cache-Control": "no-cache",
        "Pragma": "no-cache",
        "Accept-Ranges": "bytes",
        "Connection": "close"
    ]
    
    private var body = ""
    

    // MARK:    Initialisers...
    
    init(request: ClientRequest) {
        clientRequest = request
        
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = self.rfc7231Date
    }
    
    
    // MARK:    Methods...
    
    mutating func setHeader(header: String, value: String) {
        headers[header] = value
    }
    
    mutating func addBody(body: String) {
        self.body += body
    }
    
    private func addResponse(line: String, appendTo: String = "") -> String {
        return appendTo + line + self.lineEnding
    }
    
    private func addHeader(name: String, value: String, appendTo: String) -> String {
        return addResponse(line: "\(name): \(value)", appendTo: appendTo)
    }
    
    func send(responseCode: ResponseCode, body: String? = nil) {
        Console.info("response\t[\(self.request.method.rawValue)\(self.request.uri)][code=\(responseCode.rawValue)/\(responseCode)]")
        
        var reply = self.addResponse(line: "\(self.httpVersion) \(responseCode.rawValue) \(responseCode.message)")
        for header in self.headers.keys {
            reply = self.addHeader(name: header, value: self.headers[header]!, appendTo: reply)
        }
        
        var replyBody: String
        if let responseBody = body {
            replyBody = responseBody
        }
        else {
            replyBody = self.body
        }
        
        reply = addHeader(name: "Date", value: dateFormatter.string(from: Date()), appendTo: reply)
        reply = addHeader(name: "Content-Length", value: String(replyBody.utf8.count), appendTo: reply)
        
        if replyBody.characters.count > 0 {
            reply += lineEnding
            reply += replyBody
        }
        
        write(request.socket, reply, reply.utf8.count)
    }
}

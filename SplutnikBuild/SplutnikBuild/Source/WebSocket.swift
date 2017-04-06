//
//  WebSocket.swift
//  SplutnikBuild
//
//  Created by Michael Wright on 06/04/2017.
//  Copyright © 2017 wrightm@mac.com. All rights reserved.
//

import Foundation


public class WebSocket: ServerSocket {
    
    // MARK:    Initialisers...
    
    override init(name: String, port: Int, maximumConnections: Int) {
        super.init(name: name, port: port, maximumConnections: maximumConnections)
    }
    
    
    // MARK:    Methods...
    
    override open func handleRequest(socket: Int32, ip: String?, port: Int) {
        defer {
            close(socket)
        }
        
        let srcIp = ip ?? "0.0.0.0"
        Console.info("connection    [socket=\(socket)][src-ip=\(srcIp)][src-port=\(port)]")
        
        let request = ClientRequest(socket: socket)
        var response = request.getResponse()
        
        // Look for page in server's document directory - if not found try
        // find a the name & contents of a forward-to page...
        func getFileContents(uri: String) -> (contents: String?, forwardPath: String?) {
            // TODO: Should we look for a forward first - so a forward would
            //       override an existing page? If so - what if the forward
            //       doesn't exist but the non-forwarded page does?
            if let page = fileReader.getFileContents(relativePath: uri) {
                return (page, nil)
            }
            else if let forward = serverConfiguration.findMatch(sectionName: "forward", uri: uri) {
                return (fileReader.getFileContents(relativePath: forward), forward)
            }
            else {
                return (nil, nil)
            }
        }
        
        // Steps for serving up a page:
        //   1. Attempt to find an existing page - using full path for request
        //      mapped to the server's document directory. If found send it.
        //   2. If page not found, look for a match in the 'forward' section of
        //      the configuration. If found send the forwarded-to page.
        //   3. If no forward found, look for a match in the 'redirect' section.
        //      If a redirect is found, send the redirect response.
        //   4. If no page, forward, or redirect is found, send the '404 not found'
        //      response.
        let file = getFileContents(uri: request.uri)
        if file.contents != nil  {
            if let forwardPath = file.forwardPath {
                response.setHeader(header: "Forward-To", value: forwardPath)
            }
            let contentType = serverConfiguration.getContentType(name: file.forwardPath ?? request.uri) ?? response.defaultContentTypeHeader
            response.setHeader(header: "Content-Type", value: contentType)
            response.send(responseCode: .OK, body: file.contents)
        }
        else if let redirect = serverConfiguration.findMatch(sectionName: "redirect", uri: request.uri) {
            response.setHeader(header: "Location", value: redirect)
            response.send(responseCode: .Redirect, body: redirect)
        }
        else {
            response.setHeader(header: "Requested-Path", value: request.uri)
            response.send(responseCode: .NotFound, body: fileReader.getFileContents(relativePath: "404.html") ?? "missing in action")
        }
    }
}

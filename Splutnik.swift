#!/usr/bin/swift
/*
    Copyright (c) 2016, Michael Wright
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this
       list of conditions and the following disclaimer.
    2. Redistributions in binary form must reproduce the above copyright notice,
       this list of conditions and the following disclaimer in the documentation
       and/or other materials provided with the distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
    ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
    ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

    The views and conclusions contained in the software and documentation are those
    of the authors and should not be interpreted as representing official policies,
    either expressed or implied, of the FreeBSD Project.
*/

import Foundation


let serverName = "Splutnik"
let serverVersion = 0.8
let serverPort: UInt16 = 2108
let maximumConnections: Int32 = 16
let readBufferSize = 64 * 1024
let  parseParameters = true                     // Parameter parsing can be expensive.
let serverDirectory = "WebServer/"              // Location of served pages (in ~/Documents).


public struct Console {
    static func debug(_ message: String) {
        print("🙂 \(message)")
    }
    
    static func trace(_ message: String) {
        print("😶 \(message)")
    }
    
    static func error(_ message: String) {
        print("😮 \(message)")
    }
}


public extension String {
    func trim(charactersIn: String) -> String {
        return self.trim(charactersIn: CharacterSet(charactersIn: charactersIn))
    }

    func trim(charactersIn: CharacterSet = CharacterSet.whitespacesAndNewlines) -> String {
        return self.trimmingCharacters(in: charactersIn)
    }
}


public enum SocketError: Error {
    case Server(String)
    case Client(String)
}


/**
    Mutex for blocks.

*/
func lock(_ object: Any, closure: @escaping (() -> Void)) {
    defer {
        objc_sync_exit(object)
    }

    objc_sync_enter(object)
    closure()
}

func throwingLock(_ object: Any, closure: @escaping (() throws -> Void)) throws {
    defer {
        objc_sync_exit(object)
    }

    objc_sync_enter(object)
    try closure()
}


/**
    Reads files from the **WebServer** directory.

*/
public class FileReader {
    private let myLock = "file-reader-loc"

    private let basePath: URL

    var path: String {
        return basePath.path
    }
    
    init() {
        do {
            // Assume that all files to be served are in the User's 'Documents/WebServer'
            // directory...
            var homeDirectoryForCurrentUser = try FileManager().url(for: .documentDirectory, in: .userDomainMask,appropriateFor: nil, create: false) 
            homeDirectoryForCurrentUser.appendPathComponent(serverDirectory, isDirectory: true)
            basePath = homeDirectoryForCurrentUser
        }
        catch {
            // Default to wherever - need to fix this to a sensible default...
            basePath = URL(fileURLWithPath: "", isDirectory: true)
        }
    }
        
    func getFileContents(relativePath: String) -> String? {
        do {
            return try String(contentsOfFile: "\(basePath.path)\(relativePath)", encoding: .utf8)
        }
        catch let error {
            Console.error("error: \(error)")
            return nil
        }
    }
}


// File-Reading is a global - TODO: protect from race conditions.
let fileReader = FileReader()


/**
    Reads & maintains server configuration values.

*/
public class ServerConfiguration {
    let commentPrefix = "#"
    let sectionNameSuffix = ":"
    
    var sections: [String:[String:String]]

    var contentTypes = [String:String]()
    
    init() {
        var sectionName = "default"
        sections = [sectionName:[String:String]()]
        
        if let config = fileReader.getFileContents(relativePath: ".splutnik") {
            let lines = config.characters.split{$0 == "\n"}.map(String.init)
            for line in lines {
                let trimmedLine = line.trim()
                
                if !((trimmedLine.characters.count == 0) || trimmedLine.hasPrefix(commentPrefix)) {
                    if line.hasSuffix(sectionNameSuffix) {
                        sectionName = trimmedLine.trim(charactersIn: " :")
                        if sections[sectionName] == nil {
                           sections[sectionName] = [String:String]()
                        }
                    }
                    else {
                        let lineParts = trimmedLine.characters.split{$0 == "="}.map(String.init)
                        let key = lineParts[0].trim()
                        let value = (lineParts.count > 1) ? lineParts[1].trim() : ""
                        sections[sectionName]![key] = value
                    }
                }
            }

            map(sectionName: "content-type") {
                name, value in
                for suffix in name.components(separatedBy: ",") {
                    contentTypes[suffix] = value
                }
                return true
            }
        }
        else {
            print("*** ServerConfiguration: no configuration")
        }
    }
    
    func debug() {
        for sectionKey in sections.keys {
            Console.debug("\(sectionKey):")
            
            let sectionPart = sections[sectionKey]!
            for itemKey in sectionPart.keys {
                let itemValue = sectionPart[itemKey] ?? ""
                Console.debug("\t\(itemKey)=\(itemValue)")
            }
        }

        Console.debug("content-types:")
        for (suffix, contentType) in contentTypes {
            Console.debug("\t\(suffix)=\(contentType)")
        }
    }
    
    func map(sectionName: String, function: (_: String, _: String) -> Bool) {
        if let section = sections[sectionName] {
            for key in section.keys {
                if !function(key, section[key]!) {
                    break
                }
            }
        }
    }
    
    func findMatch(sectionName: String, uri: String) -> String? {
        var match: String? = nil
        
        map(sectionName: sectionName) {
            name, value in
            do {
                let regex = try NSRegularExpression(pattern: "^\(name)$", options: [])
                if regex.firstMatch(in: uri, options: [], range: NSMakeRange(0, uri.characters.count)) != nil {
                    match = value
                    return false
                }
            }
            catch {
                Console.error("ServerConfiguration.map: two problems error")
            }                
            
            return true
        }
        
        return match
    }

    func getContentType(name: String) -> String? {
        for (suffix, contentType) in contentTypes {
            if (name.hasSuffix(suffix)) {
                return contentType
            }
        }

        return nil
    }
}


// Server-Configuration is a global - TODO: protect from race conditions.
let serverConfiguration = ServerConfiguration()


/**
    Provides basic server socket functionality.

*/
public class ServerSocket { 
    private let port: UInt16
    
    private var acceptConnections: Bool

    init(port: UInt16) {
        Console.debug("ServerSocket.init [port=\(port)]")
        
        self.port = port
        acceptConnections = false
    }

    func handleRequest(socket: Int32, ip: String?, port: Int) {
        let srcIp = ip ?? "0.0.0.0"
        Console.trace("ServerSocket.handleRequest [socket=\(socket)][src-ip=\(srcIp)][src-port=\(port)]")
        
        close(socket)
    }

    func start() throws {
        var hints = addrinfo(ai_flags: AI_PASSIVE, ai_family: AF_UNSPEC, ai_socktype: SOCK_STREAM, ai_protocol: 0, ai_addrlen: 0, ai_canonname: nil, ai_addr: nil, ai_next: nil)
        var servinfo: UnsafeMutablePointer<addrinfo>? = nil
        var status = getaddrinfo(nil, String(port), &hints, &servinfo)
        if status != 0 {
            throw SocketError.Server("create address failure")
        }
        
        defer {
            if servinfo != nil {
                freeaddrinfo(servinfo)
            }
        }

        let socketDescriptor = socket(servinfo!.pointee.ai_family, servinfo!.pointee.ai_socktype, servinfo!.pointee.ai_protocol)
        if socketDescriptor == -1 {
            throw SocketError.Server("create socket failure")
        }

        defer {
            close(socketDescriptor)
        }

        status = bind(socketDescriptor, servinfo!.pointee.ai_addr, servinfo!.pointee.ai_addrlen)
        if status != 0 {
            throw SocketError.Server("bind failure")
        }

        status = listen(socketDescriptor, maximumConnections)
        if status != 0 {
            throw SocketError.Server("listen failure")
        }

        let connectionQueue = DispatchQueue(
            label: "\(serverName)ConnectionQueue",
            attributes: [.concurrent]
        )

        acceptConnections = true
        while acceptConnections {
            var connectedAddrInfo = sockaddr(sa_len: 0, sa_family: 0, sa_data: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
            var connectedAddrInfoLength = socklen_t(MemoryLayout<sockaddr>.size)
            
            let clientSocket = accept(socketDescriptor, &connectedAddrInfo, &connectedAddrInfoLength)
            if clientSocket == -1 {
                printStatusError(message: "accept")
                continue
            }

            connectionQueue.async() {
                let (ipAddress, servicePort) = self.getSocketDescription(addr: &connectedAddrInfo)
                self.handleRequest(socket: clientSocket, ip: ipAddress, port: Int(servicePort ?? "0")!)
            }
        }
    }

    func stop() {
        acceptConnections = false
    }

    private func getSocketDescription(addr: UnsafePointer<sockaddr>) -> (String?, String?) {
        var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        var serviceBuffer = [CChar](repeating: 0, count: Int(NI_MAXSERV))
        if getnameinfo(addr, socklen_t(addr.pointee.sa_len), &hostBuffer, socklen_t(hostBuffer.count), &serviceBuffer, socklen_t(serviceBuffer.count), NI_NUMERICHOST | NI_NUMERICSERV) == 0 {
            return (String(cString: hostBuffer), String(cString: serviceBuffer))
        }
        else {
            return (nil, nil)
        }
    }

    private func printStatusError(message: String, error: String? = nil) {
        let errorString = (error != nil) ? error : String(utf8String: strerror(errno)) ?? "unknown"
        Console.error("\(message) [error-code=\(errno)][error-message=\(errorString)]")
    }
}


/**
    Handles web-browser requests.

*/
public class WebSocket: ServerSocket {
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

        var socket: Int32
        
        var method: Method = .Unknown

        var uri: String = ""

        var paramString: String = ""

        var parameters = [String:String]()

        var version: String = ""

        var headers = [String:String]()

        var body: String = ""

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
            
            Console.trace("request\t[\(method.rawValue)\(uri)]")
            for (name, value) in parameters {
                Console.trace("parameter\t[name=\(name)][value=\(value)]")
            }
            for (name, value) in headers {
                Console.trace("header\t[name=\(name)][value=\(value)]")
            }
        }
        
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
        
        let httpVersion = "HTTP/1.1"
        let lineEnding = "\r\n"
        let rfc7231Date = "EEE, d MMM yyyy HH:mm:ss z"

        // Default value of "Content-Type" header...
        let defaultContentTypeHeader = "text/html; charset=utf-8" 
        
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
            "Server": "\(serverName)/\(serverVersion) (macOS))",
            "Cache-Control": "no-cache",
            "Pragma": "no-cache",
            "Accept-Ranges": "bytes",
            "Connection": "close"
        ]
        
        private var body = ""
        
        init(request: ClientRequest) {
            clientRequest = request
            
            dateFormatter = DateFormatter()
            dateFormatter.dateFormat = self.rfc7231Date
        }
        
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
            Console.trace("response\t[\(self.request.method.rawValue)\(self.request.uri)][code=\(responseCode.rawValue)/\(responseCode)]")
            
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

    override init(port: UInt16) {
        super.init(port: port)
    }

    override func handleRequest(socket: Int32, ip: String?, port: Int) {
        defer {
            close(socket)
        }

        let srcIp = ip ?? "0.0.0.0"
        Console.trace("connection    [socket=\(socket)][src-ip=\(srcIp)][src-port=\(port)]")
        
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


do {
    Console.trace("\(serverName) \(serverVersion)")

    Console.trace("document base-path: '\(fileReader.path)'")
    serverConfiguration.debug()

    let webSocket = WebSocket(port: serverPort)
    try webSocket.start()
}
catch SocketError.Server(let message) {
    Console.debug("server socket error: (\(message))")
}
catch SocketError.Client(let message) {
    Console.debug("client socket error: (\(message))")
}

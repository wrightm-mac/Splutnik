//
//  ServerSocket.swift
//  SplutnikBuild
//
//  Created by Michael Wright on 06/04/2017.
//  Copyright © 2017 wrightm@mac.com. All rights reserved.
//

import Foundation


open class ServerSocket {
    
    // MARK:    Fields...
    
    public let name: String
    
    public let port: UInt16
    
    public let maximumConnections: Int32
    
    public private(set) var acceptConnections: Bool
    
    
    // MARK:    Initialisers...
    
    init(name: String, port: Int, maximumConnections: Int) {
        Console.debug("ServerSocket.\(#function) [port=\(port)]")
        
        self.name = name
        self.port = UInt16(port)
        self.maximumConnections = Int32(maximumConnections)
        
        acceptConnections = false
    }
    
    
    // MARK:    Methods...
    
    open func handleRequest(socket: Int32, ip: String?, port: Int) {
        let srcIp = ip ?? "0.0.0.0"
        Console.info("ServerSocket.handleRequest [socket=\(socket)][src-ip=\(srcIp)][src-port=\(port)]")
        
        close(socket)
    }
    
    open func start() throws {
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
            label: "\(name)ConnectionQueue",
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
        Console.error("\(message) [error-code=\(errno)][error-message=\(String(describing: errorString))]")
    }
}

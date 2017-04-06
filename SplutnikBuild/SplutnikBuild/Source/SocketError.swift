//
//  SocketError.swift
//  SplutnikBuild
//
//  Created by Michael Wright on 06/04/2017.
//  Copyright © 2017 wrightm@mac.com. All rights reserved.
//

import Foundation


public enum SocketError: Error {
    case Server(String)
    case Client(String)
}

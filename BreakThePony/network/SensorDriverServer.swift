//
//  SensorDriverServer.swift
//  BreakThePony
//
//  Created by Jonathan Bredin on 1/15/18.
//  Copyright © 2018 Jonathan Bredin. All rights reserved.
//

import Foundation
import CoreFoundation
import os.log

enum SensorDriverError : Error {
  case accept(Int32)
  case bind(Int32)
  case listen(Int32)
  case network(Int32)
}

//
//  Handle network requests to query quadcopter state and to send results.
//
class SensorDriverServer {
  
  // Run loop to wait for requests and quickly handle them.
  func run() throws {
    var serverSocket: ServerConnection
    var clientFd: Int32
    let err: Int32 = 0
    
    do {
      try serverSocket = ServerConnection()
      while true {
        try clientFd = serverSocket.waitForClient()
        os_log("connect %u", clientFd)
        close(clientFd)
      }
      defer {
        serverSocket.closeServer()
      }
    } catch SensorDriverError.accept(err) {
      os_log("cannot accept server socket: %s", strerror(err))
      throw SensorDriverError.network(err)
    } catch SensorDriverError.bind(err) {
      os_log("cannot accept bind socket: %s", strerror(err))
      throw SensorDriverError.network(err)
    } catch SensorDriverError.listen(err) {
      os_log("cannot listen: %s", strerror(err))
      throw SensorDriverError.network(err)
    }
  } // run
  
}

//
// Encapsulate server connection state.
//
class ServerConnection {
  private var sockAddr = sockaddr_in()
  private let socketFd = socket(AF_INET, SOCK_STREAM, 0)
  
  private let BACKLOG: Int32 = 10
  private static let PORT: in_port_t = 9878
  private let SOCK_LEN = socklen_t(MemoryLayout<sockaddr_in>.size)
  
  init(port: in_port_t = PORT) throws {
    memset(&sockAddr, 0, Int(SOCK_LEN))
    sockAddr.sin_addr.s_addr = INADDR_ANY.bigEndian
    sockAddr.sin_family = sa_family_t(AF_INET)
    sockAddr.sin_port = port.bigEndian
    
    if bind(socketFd, safeSockAddr(sa_in: sockAddr), SOCK_LEN) != 0 {
      throw SensorDriverError.bind(errno)
    }
    
    if listen(socketFd, BACKLOG) != 0 {
      throw SensorDriverError.listen(errno)
    }
  }
  
  // Terminate the server connection.  Do not call additional operations
  // on the object after calling this method.
  func closeServer() {
    close(socketFd)
  }
  
  // Transform sockaddr_in to sockaddr* with a cast.
  // Returning pointer to variable on stack doesn't seem like it should work...
  func safeSockAddr(sa_in: sockaddr_in) -> UnsafeMutablePointer<sockaddr> {
    var sockAddr = sa_in
    return withUnsafeMutablePointer(to: &sockAddr) {
      $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        return $0
      }
    }
  }
  
  // Wait for a client connection and return a file descriptor to the new client
  // connection.
  func waitForClient() throws -> Int32 {
    os_log("accepting on port=%u", sockAddr.sin_port.bigEndian)
    var vSockLen = SOCK_LEN
    let toClientFd = accept(socketFd, safeSockAddr(sa_in: sockAddr), &vSockLen)
    if (toClientFd < 0) {
      throw SensorDriverError.accept(errno)
    }
    return toClientFd
  }
}

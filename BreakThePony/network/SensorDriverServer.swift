//
//  SensorDriverServer.swift
//  BreakThePony
//
//  Created by Jonathan Bredin on 1/15/18.
//  Copyright © 2018 Jonathan Bredin. All rights reserved.
//

import CoreFoundation
import Foundation
import os.log

enum SensorDriverError : Error {
  case accept(Int32)
  case bind(Int32)
  case listen(Int32)
  case network(Int32)
}

//
// Commands to send to the server
//
enum CommCommand: String {
  case get = "get"
  case put = "put"
  case alternate = "alt"
  case stream = "str"
}

protocol CommandExecutor {
  var ioF: Int32 { get }
  func run()
}

func errStr(_ errno: Int32) -> String {
  return String(cString: strerror(errno))
}

func ignoreSigPipe(fd: Int32) {
  var ignore = 1
  signal(SIGPIPE, {(err: Int32) in os_log("signal %d", err) })
  if 0 != setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &ignore, socklen_t(MemoryLayout.size(ofValue: ignore))) {
    os_log("setsockopt error attempting to ignore SIGPIPE: %@", errStr(errno))
  }
}

//
//  Handle network requests to query quadcopter state and to send results.
//
class SensorDriverServer {
  private let copterState: CopterStateServer
  private let dispatch = DispatchQueue(
    label: "org.bredin.BreakThePony.client_handler",
    attributes: .concurrent)
  
  init(copterState: CopterStateServer) {
    self.copterState = copterState
  }
  
  func handleClientRequest(fd: Int32) {
    os_log("handleClientRequest %u", fd)
    // XXX catch error, limit wait?
    let rawCmd = SensorDriverServer.readToken(fd: fd)
    guard let cmd = CommCommand(rawValue: rawCmd.lowercased()) else {
      os_log("invalid command: %@", rawCmd)
      close(fd)
      return
    }
    os_log("read %@", rawCmd)
    
    let exe: CommandExecutor?
    switch cmd {
    case CommCommand.alternate:
      exe = AlternateCommand(copterState: copterState, f: fd)
    case CommCommand.get:
      exe = GetCommand(copterState: copterState, f: fd)
    case CommCommand.put:
      exe = PutCommand(copterState: copterState, f: fd)
    case CommCommand.stream:
      exe = StreamCommand(copterState: copterState, f: fd)
    }
    exe?.run()
  }
  
  // Read file descriptor slowly byte by byte until \r\n.
  static func readToken(fd: Int32) -> String {
    var result = ""
    var c: Character
    let buff = UnsafeMutablePointer<UInt8>.allocate(capacity: 1)
    
    func isEnd(c: Character) -> Bool {
      return c == "\r" || c == "\n"
    }
    
    while read(fd, buff, 1) > 0 {
      c = Character(UnicodeScalar(buff[0]))
      if isEnd(c: c) {
        read(fd, buff, 1)
        c = Character(UnicodeScalar(buff[0]))
        if isEnd(c: c) {
          break
        } else {
          result.append("\r\n")
        }
      } else {
        result.append(c)
      }
    }
    
    defer {
      buff.deallocate(capacity: 1)
    }
    return result
  }
  
  // Run loop to wait for requests and quickly handle them.
  func run() throws {
    var serverSocket: ServerConnection
    var clientFd: Int32
    let err: Int32 = 0
    
    do {
      try serverSocket = ServerConnection()
      defer {
        serverSocket.closeServer()
      }
      while true {
        try clientFd = serverSocket.waitForClient()
        dispatch.async {
          self.handleClientRequest(fd: clientFd)
        }
      }
    } catch SensorDriverError.accept(err) {
      os_log("cannot accept server socket: %@", errStr(err))
      throw SensorDriverError.network(err)
    } catch SensorDriverError.bind(err) {
      os_log("cannot accept bind socket: %@", errStr(err))
      throw SensorDriverError.network(err)
    } catch SensorDriverError.listen(err) {
      os_log("cannot listen: %@", errStr(err))
      throw SensorDriverError.network(err)
    } catch {
      os_log("unhandled exception")
    }
  } // run
  
  static func sendToken(fd: Int32, token: String) throws {
    var buff = UnsafePointer<Int8>((token as NSString).utf8String)
    ignoreSigPipe(fd: fd)
    var numWritten = write(fd, buff, token.count)
    if numWritten != token.count {
      let errNum = errno
      os_log("only wrote %d of %d bytes: %@", numWritten, token.count, errStr(errNum))
      throw SensorDriverError.network(errNum)
    }
    
    buff = UnsafePointer<Int8>(("\r\n" as NSString).utf8String)
    numWritten = write(fd, buff, 2)
    if numWritten != 2 {
      let errNum = errno
      os_log("only wrote %d of 2 terminating bytes: %@", numWritten, errStr(errNum))
      throw SensorDriverError.network(errNum)
    }
  }
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
    
    if bind(socketFd, ServerConnection.safeSockAddr(sa_in: sockAddr), SOCK_LEN) != 0 {
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
  static func safeSockAddr(sa_in: sockaddr_in) -> UnsafeMutablePointer<sockaddr> {
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
    let toClientFd = accept(socketFd, ServerConnection.safeSockAddr(sa_in: sockAddr), &vSockLen)
    ignoreSigPipe(fd: toClientFd)
    if (toClientFd < 0) {
      throw SensorDriverError.accept(errno)
    }
    return toClientFd
  }
}

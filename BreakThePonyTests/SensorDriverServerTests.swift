//
//  SensorDriverServerTests.swift
//  BreakThePonyTests
//
//  Created by Jonathan Bredin on 1/19/18.
//  Copyright © 2018 Jonathan Bredin. All rights reserved.
//

import XCTest
import os.log

class SensorDriverServerTests: XCTestCase {
  
  func makePipe() -> UnsafeMutablePointer<Int32> {
    let fds = UnsafeMutablePointer<Int32>.allocate(capacity: 2)
    socketpair(AF_UNIX, SOCK_STREAM, 0, fds)
    // pipe(fds)
    return fds
  }
  
  override func setUp() {
    super.setUp()
  }
  
  override func tearDown() {
    super.tearDown()
  }
  
  func testCastSockAddr() {
    var sockAddr = sockaddr_in()
    let port: in_port_t = 1111
    sockAddr.sin_port = port
    let _ = ServerConnection.safeSockAddr(sa_in: sockAddr)
    // extract port from casted?
  }
  
  func testAlternateCommand() {
    let state = SimpleCopterStateServer()
    let s = SensorDriverServer(copterState: state)
    let fds = makePipe()
    let dispatch = DispatchQueue(
      label: "org.bredin.BreakThePony.alternate_command_test",
      attributes: .concurrent)
    defer {
      free(fds)
    }
    
    state.updateSensors([1.0, 2.0])
    let cmd = CommCommand(rawValue: "alt")
    SensorDriverServer.sendToken(fd: fds[1], token: cmd!.rawValue)
    SensorDriverServer.sendToken(fd: fds[1], token: "3.0, 4.0")
    // XXX terminate?

    dispatch.async {
      s.handleClientRequest(fd: fds[0])
    }
    
    let response = SensorDriverServer.readToken(fd: fds[1])
    XCTAssertEqual("1.0, 2.0", response) // XXX flakey
  }
  
  func testGetCommand() {
    let state = SimpleCopterStateServer()
    let s = SensorDriverServer(copterState: state)
    let fds = makePipe()
    defer {
      free(fds)
    }
    
    state.updateSensors([1.0, 2.0])
    let cmd = CommCommand(rawValue: "get")
    SensorDriverServer.sendToken(fd: fds[1], token: cmd!.rawValue)
    s.handleClientRequest(fd: fds[0])
    let response = SensorDriverServer.readToken(fd: fds[1])
    XCTAssertEqual("1.0, 2.0", response)
  }
  
  func testInstantiateConnection() throws {
    let err: Int32 = 0
    do {
      let conn = try ServerConnection()
      defer {
        conn.closeServer()
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
  }
  
  func testInstantiateServer() {
    let state = SimpleCopterStateServer()
    let _ = SensorDriverServer(copterState: state)
  }
  
  func testPutCommand() {
    let state = SimpleCopterStateServer()
    let s = SensorDriverServer(copterState: state)
    let fds = makePipe()
    defer {
      free(fds)
    }
    
    let cmd = CommCommand(rawValue: "put")
    SensorDriverServer.sendToken(fd: fds[1], token: cmd!.rawValue)
    SensorDriverServer.sendToken(fd: fds[1], token: "1.0, 2.0") // XXX bidirectional danger?
    s.handleClientRequest(fd: fds[0])
    
    let newState = state.readSensors()
    XCTAssertEqual([1.0, 2.0], newState)
  }
  
  func testReadToken() {
    let fds = makePipe()
    defer {
      free(fds)
    }
    let tokenSent = "Hello"
    SensorDriverServer.sendToken(fd: fds[1], token: tokenSent + "\r\n")
    let tokenRead = SensorDriverServer.readToken(fd: fds[0])
    XCTAssertEqual(tokenSent, tokenRead)
  }
  
  func testPerformanceExample() {
    // This is an example of a performance test case.
    self.measure {
      // Put the code you want to measure the time of here.
    }
  }
  
}

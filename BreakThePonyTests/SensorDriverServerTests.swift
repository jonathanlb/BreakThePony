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
    let _ = SensorDriverServer()
  }
  
  func testReadToken() {
    let s = SensorDriverServer()
    let fds = UnsafeMutablePointer<Int32>.allocate(capacity: 2)
    pipe(fds) // XXX improper use of pipe -- nothing sent?
    let tokenSent = "Hello"
    s.sendToken(fd: fds[1], token: tokenSent + "\r\n")
    let tokenRead = s.readToken(fd: fds[0])
    XCTAssertEqual(tokenSent, tokenRead)
  }
  
  func testPerformanceExample() {
    // This is an example of a performance test case.
    self.measure {
      // Put the code you want to measure the time of here.
    }
  }
  
}

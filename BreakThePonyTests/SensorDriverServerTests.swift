//
//  SensorDriverServerTests.swift
//  BreakThePonyTests
//
//  Created by Jonathan Bredin on 1/19/18.
//  Copyright © 2018 Jonathan Bredin. All rights reserved.
//

import CoreBluetooth
import XCTest
import os.log

class SensorDriverServerTests: XCTestCase {
  
  private func makeSocket() -> UnsafeMutablePointer<Int32> {
    let fds = UnsafeMutablePointer<Int32>.allocate(capacity: 2)
    socketpair(AF_UNIX, SOCK_STREAM, 0, fds)
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
  
  func testAlternateCommand() { // XXX doesn't check power values sent
    let state = SimpleCopterStateServer()
    let s = SensorDriverServer(copterState: state)
    let fds = makeSocket()
    let dispatch = DispatchQueue(
      label: "org.bredin.BreakThePony.alternate_command_test",
      attributes: .concurrent)
    defer {
      free(fds)
    }
    
    let id0 = CBUUID()
    state.updateSensor(sensor: id0, value: 1.0)
    let cmd = CommCommand(rawValue: "alt")
    SensorDriverServer.sendToken(fd: fds[1], token: cmd!.rawValue)
    SensorDriverServer.sendToken(fd: fds[1], token: "1.0, -1.0")

    dispatch.async {
      s.handleClientRequest(fd: fds[0])
    }
    
    let response = SensorDriverServer.readToken(fd: fds[1])
    XCTAssertEqual(id0.description + ": 1.0", response)
  }
  
  func testGetCommand() {
    let state = SimpleCopterStateServer()
    let s = SensorDriverServer(copterState: state)
    let fds = makeSocket()
    
    let id0 = CBUUID()
    state.updateSensor(sensor: id0, value: 2.0)
    let cmd = CommCommand(rawValue: "get")
    SensorDriverServer.sendToken(fd: fds[1], token: cmd!.rawValue)
    s.handleClientRequest(fd: fds[0])
    let response = SensorDriverServer.readToken(fd: fds[1])
    XCTAssertEqual(id0.description + ": 2.0", response)
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
    class LocalCopterState : SimpleCopterStateServer {
      var actuators = [0.0, 0.0, 0.0]
      override func updateActuators(_ power: [Double]) {
        actuators = power
      }
    }
    let state = LocalCopterState()
    let s = SensorDriverServer(copterState: state)
    let fds = makeSocket()
    defer {
      free(fds)
    }
    
    let cmd = CommCommand(rawValue: "put")
    SensorDriverServer.sendToken(fd: fds[1], token: cmd!.rawValue)
    SensorDriverServer.sendToken(fd: fds[1], token: "1.0, 2.0, -3.0")
    s.handleClientRequest(fd: fds[0])
    XCTAssertEqual([1.0, 2.0, -3.0], state.actuators)
  }
  
  func testReadToken() {
    let fds = makeSocket()
    defer {
      free(fds)
    }
    let tokenSent = "Hello"
    SensorDriverServer.sendToken(fd: fds[1], token: tokenSent + "\r\n")
    let tokenRead = SensorDriverServer.readToken(fd: fds[0])
    XCTAssertEqual(tokenSent, tokenRead)
  }
  
  func testStreamCommand() {
    let dispatch = DispatchQueue(
      label: "org.bredin.BreakThePony.stream_command_test",
      attributes: .concurrent)
    let state = SimpleCopterStateServer()
    let s = SensorDriverServer(copterState: state)
    let fds = makeSocket()
    // don't defer/free with multithreading, hope OS cleans up....
    
    let id0 = CBUUID()
    
    state.updateSensor(sensor: id0, value: 1.0)
    let cmd = CommCommand(rawValue: "str")
    SensorDriverServer.sendToken(fd: fds[1], token: cmd!.rawValue)
    
    dispatch.async {
      s.handleClientRequest(fd: fds[0])
      state.updateSensor(sensor: id0, value: 2.0)
      state.updateSensor(sensor: id0, value: 3.0)
    }
    
    var response = SensorDriverServer.readToken(fd: fds[1])
    XCTAssertEqual(id0.description + ": 2.0", response)
    
    response = SensorDriverServer.readToken(fd: fds[1])
    XCTAssertEqual(id0.description + ": 3.0", response)
    
    // Different ordering?
    state.updateSensor(sensor: id0, value: 4.0)
    response = SensorDriverServer.readToken(fd: fds[1])
    XCTAssertEqual(id0.description + ": 4.0", response)
  }
}

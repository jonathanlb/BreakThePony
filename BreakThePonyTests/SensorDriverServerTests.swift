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
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testInstantiateConnection() throws {
    let err: Int32 = 0
    do {
      let conn = try ServerConnection()
      conn.closeServer()
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
  
  func testPerformanceExample() {
    // This is an example of a performance test case.
    self.measure {
      // Put the code you want to measure the time of here.
    }
  }
  
}

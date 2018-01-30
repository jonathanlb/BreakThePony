//
//  BreakThePonyTests.swift
//  BreakThePonyTests
//
//  Created by Jonathan Bredin on 1/9/18.
//  Copyright © 2018 Jonathan Bredin. All rights reserved.
//

import XCTest
import CoreBluetooth

class BluetoothTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
  }
  
  override func tearDown() {
    super.tearDown()
  }
  
  func testClientStartStop() {
    let copterState = SimpleCopterStateServer()
    let client = CentralBluetoothClient(copterState: copterState)
    XCTAssert(!client.isScanning(), "start-up shouldn't activate bluetooth")
    client.start()
    client.stop()
    XCTAssert(!client.isScanning(), "shut down should stop bluetooth")
  }
  
  /*
  func testIsNilCopter() {
    let client = CentralBluetoothClient()
    class PeripheralStub : CBPeripheral {
    }
    let nameStub = PeripheralStub()
    XCTAssert(!client.isQuadcopter(peripheral: nameStub))
  }
 */
  
  func testPerformanceExample() {
    // This is an example of a performance test case.
    self.measure {
      // Put the code you want to measure the time of here.
    }
  }
  
}

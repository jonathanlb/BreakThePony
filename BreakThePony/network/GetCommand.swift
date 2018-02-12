//
//  GetCommand.swift
//  BreakThePony
//
//  State retrieval from Protocol::processDataIn()
//  https://github.com/Crazepony/crazepony-android-client-none/blob/master/app/src/main/java/com/test/Crazepony/Protocol.java
//
//  Header is "$m>" byte_data_size
//  Error/termination is "!"
//
//  Created by Jonathan Bredin on 1/28/18.
//  Copyright © 2018 Jonathan Bredin. All rights reserved.
//

import CoreBluetooth
import Foundation

class GetCommand : CommandExecutor {
  private let copterState: CopterStateServer
  let ioF: Int32
  
  init(copterState: CopterStateServer, f: Int32) {
    self.copterState = copterState
    ioF = f
  }
  
  static func marshallSensorReading(sensor: CBUUID, value: Double) -> String {
    return sensor.description + ": " + value.description
  }
  
  static func marshallState(_ state: [CBUUID: Double]) -> String {
    let stateStr = state.description
    return String(stateStr.dropFirst().dropLast())
  }
  
  static func marshallState(_ state: [Double]) -> String {
    let stateStr = state.description
    return String(stateStr.dropFirst().dropLast())
  }
  
  func run() {
    let readings = copterState.readSensors()
    SensorDriverServer.sendToken(fd: ioF,
                                 token: GetCommand.marshallState(readings))
    close(ioF)
  }
}

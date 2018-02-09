//
//  StreamCommand.swift
//  BreakThePony
//
//  Created by Jonathan Bredin on 2/8/18.
//  Copyright © 2018 Jonathan Bredin. All rights reserved.
//

import CoreBluetooth
import Foundation

class StreamCommand : CommandExecutor {
  private let copterState: CopterStateServer
  let ioF: Int32
  
  init(copterState: CopterStateServer, f: Int32) {
    self.copterState = copterState
    self.ioF = f
  }
  
  func run() {
    copterState.subscribeSensors({
      (sensor: CBUUID, value: Double) -> Void in
      SensorDriverServer.sendToken(fd: self.ioF, token: GetCommand.marshallSensorReading(sensor: sensor, value: value))
    })
    // terminates, early.  Make command terminate connection
  }
}

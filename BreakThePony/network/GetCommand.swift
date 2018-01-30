//
//  GetCommand.swift
//  BreakThePony
//
//  Created by Jonathan Bredin on 1/28/18.
//  Copyright © 2018 Jonathan Bredin. All rights reserved.
//

import Foundation

class GetCommand : CommandExecutor {
  private let copterState: CopterStateServer
  let ioF: Int32
  
  init(copterState: CopterStateServer, f: Int32) {
    self.copterState = copterState
    ioF = f
  }
  
  func run() {
    var stateStr = copterState.readSensors().description
    stateStr = String(stateStr.dropFirst().dropLast())
    SensorDriverServer.sendToken(fd: ioF, token: stateStr)
  }
}

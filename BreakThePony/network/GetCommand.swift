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

import Foundation
import os.log

class GetCommand : CommandExecutor {
  private let copterState: CopterStateServer
  private let closeOnRead: Bool
  let ioF: Int32
  
  init(copterState: CopterStateServer, f: Int32, closeOnRead: Bool = true) {
    self.copterState = copterState
    self.closeOnRead = closeOnRead
    ioF = f
  }
  
  static func marshallState(_ state: [String: Double]) -> String {
    let stateStr = state.description
    return String(stateStr.dropFirst().dropLast())
  }
  
  static func marshallState(_ state: [Double]) -> String {
    let stateStr = state.description
    return String(stateStr.dropFirst().dropLast())
  }
  
  func run() {
    let readings = copterState.readSensors()
    do {
      try SensorDriverServer.sendToken(fd: ioF,
                                       token: GetCommand.marshallState(readings))
    } catch {
      os_log("error get command %d", errno)
    }
    if closeOnRead {
      close(ioF)
    }
  }
}

//
//  PutCommand.swift
//  BreakThePony
//
//  Expect a string in the form <value0>, <value1>, ...
//
//  Created by Jonathan Bredin on 1/29/18.
//  Copyright © 2018 Jonathan Bredin. All rights reserved.
//

import Foundation

class PutCommand : CommandExecutor {
  private let copterState: CopterStateServer
  let ioF: Int32
  
  init(copterState: CopterStateServer, f: Int32) {
    self.copterState = copterState
    ioF = f
  }
  
  func run() {
    let putCommand = SensorDriverServer.readToken(fd: ioF)
    close(ioF)
    let newState = putCommand.split(separator: ",").map{
      Double($0.trimmingCharacters(in: [" "]))!
    }
    copterState.updateActuators(newState)
  }
}

//
//  CopterStateServer.swift
//  BreakThePony
//
//  Created by Jonathan Bredin on 1/29/18.
//  Copyright © 2018 Jonathan Bredin. All rights reserved.
//

import Foundation

//
// Interface to read sensor state and issue motor commands.
//
protocol CopterStateServer {
  func readSensors() -> [Double]
  func updateSensors(_ state: [Double])
  // func subscribeState()
  
  func updateActuators(_ power: [Double])
}

//
// Dummy state update
//
class SimpleCopterStateServer : CopterStateServer {
  // TODO: make immutable
  private var state : [Double] = [0.0, 0.0, 0.0, 0.0]
  
  func readSensors() -> [Double] {
    return state
  }
  
  func updateSensors(_ state: [Double]) {
    self.state = state
  }
  
  func updateActuators(_ power: [Double]) {
    
  }
}

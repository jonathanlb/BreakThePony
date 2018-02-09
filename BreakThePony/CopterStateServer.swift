//
//  CopterStateServer.swift
//  BreakThePony
//
//  Created by Jonathan Bredin on 1/29/18.
//  Copyright © 2018 Jonathan Bredin. All rights reserved.
//

import CoreBluetooth
import Foundation

//
// Interface to read sensor state and issue motor commands.
//
protocol CopterStateServer {
  func readSensors() -> [CBUUID: Double]
  func updateSensor(sensor: CBUUID, value: Double)
  
  func subscribeSensors(_ callback: @escaping (CBUUID, Double) -> Void)
  
  func updateActuators(_ power: [Double])
}

//
// Dummy state update
//
class SimpleCopterStateServer : CopterStateServer {
  private var state: [CBUUID: Double] = [:] // change to dictionary?
  private var callbacks: [(CBUUID, Double) -> Void] = []
  
  func readSensors() -> [CBUUID: Double] {
    objc_sync_enter(state)
    let result = self.state // really?
    objc_sync_exit(state)
    
    return result
  }
  
  func subscribeSensors(_ callback: @escaping (CBUUID, Double) -> Void) {
    callbacks.append(callback)
  }
  
  func updateSensor(sensor: CBUUID, value: Double) {
    updateState(sensor: sensor, value: value)
    objc_sync_enter(state)
      for cb in self.callbacks {
        cb(sensor, value)
      }
    objc_sync_exit(state)
  }
  
  func updateState(sensor: CBUUID, value: Double) {
    objc_sync_enter(state)
    self.state[sensor] = value
    objc_sync_exit(state)
  }
  
  func updateActuators(_ power: [Double]) {
    
  }
}

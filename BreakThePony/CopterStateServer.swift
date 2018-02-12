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
  
  func subscribeSensors(tag: String, callback: @escaping (CBUUID, Double) -> Void)
  @discardableResult func unsubscribeSensors(tag: String) -> Bool

  func updateActuators(_ power: [Double])
}

//
// Dummy state update
//
class SimpleCopterStateServer : CopterStateServer {
  private var state: [CBUUID: Double] = [:]
  private var callbacks: [String: (CBUUID, Double) -> Void] = [:]
  
  func readSensors() -> [CBUUID: Double] {
    objc_sync_enter(state)
    let result = self.state // really?
    objc_sync_exit(state)
    
    return result
  }
  
  func subscribeSensors(tag: String, callback: @escaping (CBUUID, Double) -> Void) {
    objc_sync_enter(state)
    callbacks[tag] = callback
    objc_sync_exit(state)
  }
  
  //
  // Update the sensor reading and notify all subscribers.
  //
  func updateSensor(sensor: CBUUID, value: Double) {
    updateState(sensor: sensor, value: value)
    objc_sync_enter(state)
      for cb in self.callbacks.values {
        cb(sensor, value)
      }
    objc_sync_exit(state)
  }
  
  //
  // Update the sensor state.
  //
  private func updateState(sensor: CBUUID, value: Double) {
    objc_sync_enter(state)
    self.state[sensor] = value
    objc_sync_exit(state)
  }
  
  func updateActuators(_ power: [Double]) {
    // TODO
  }
  
  @discardableResult func unsubscribeSensors(tag: String) -> Bool {
    var result: Bool
    objc_sync_enter(state)
    result = nil != callbacks.removeValue(forKey: tag)
    objc_sync_exit(state)
    return result
  }
}

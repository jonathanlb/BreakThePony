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
  func readSensors() -> [String: Double]
  func updateSensors(_ sensorMap: [String: Double])
  
  func subscribeSensors(tag: String, callback: @escaping ([String: Double]) -> Void)
  @discardableResult func unsubscribeSensors(tag: String) -> Bool

  func updateActuators(_ power: [Double])
}

//
// Dummy state update
//
class SimpleCopterStateServer : CopterStateServer {
  private var state: [String: Double] = [:]
  private var callbacks: [String: ([String: Double]) -> Void] = [:]
  
  func readSensors() -> [String: Double] {
    objc_sync_enter(state)
    let result = self.state // really?
    objc_sync_exit(state)
    
    return result
  }
  
  func subscribeSensors(tag: String, callback: @escaping ([String: Double]) -> Void) {
    objc_sync_enter(state)
    callbacks[tag] = callback
    objc_sync_exit(state)
  }
  
  //
  // Update the sensor reading and notify all subscribers.
  //
  func updateSensors(_ sensorMap: [String: Double]) {
    objc_sync_enter(state)
    updateState(sensorMap)
      for cb in self.callbacks.values {
        cb(state)
      }
    objc_sync_exit(state)
  }
  
  //
  // Update the sensor state.
  //
  func updateState(_ sensorMap: [String: Double]) {
    objc_sync_enter(state)
    self.state = sensorMap
    self.state.merge(sensorMap,
                     uniquingKeysWith: {(current: Double, new: Double) in new })
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

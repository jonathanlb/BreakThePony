//
//  CommandAccumulator.swift
//  BreakThePony
//
//  Created by Jonathan Bredin on 2/16/18.
//  Copyright © 2018 Jonathan Bredin. All rights reserved.
//

import Foundation
import os.log

//
// Read sensor data to construct the copter state.
// We expect a payload of
// "$M>" data-size-byte command checksum-byte
// Where the command is
// 2B roll angle*10, 2B pitch angle*10, 2B yaw angle*10, 4B altitude*100, 2B volts*100, 2B speedZ*1000
// From https://github.com/Crazepony/crazepony-android-client-none/blob/master/app/src/main/java/com/test/Crazepony/Protocol.java
//
// What we really see
// 12 messages
// values: 0, 0xff, 1000 (0x03e8), 1000, 0, 0, 0, 0, 1, 0xffffffff, 33333 (0x8235), 0
// bytes:  1, 2,    2,             2,    4, 4, 4, 4, 1, 4,          2,              2
//
// Sending:
// "$M<" data-size-byte command-byte payload checksum
class CommandAccumulator {
  private var readState = 0
  private static let NUM_PACKETS_TO_READ = 12
  private var reading = Array<UInt32>(repeating: 0, count: CommandAccumulator.NUM_PACKETS_TO_READ)
  
  private let copterState: CopterStateServer
  
  init(copterState: CopterStateServer) {
    self.copterState = copterState
  }
  
  func add(_ data: Data) {
    objc_sync_enter(self)
    reading[readState] = CommandAccumulator.readData(from: data)
    readState += 1
    if readState == CommandAccumulator.NUM_PACKETS_TO_READ {
      os_log("read: %@", reading.description)
      // XXX quickie
      var stateToSend: [String: Double] = [:]
      for i in reading.enumerated() {
        stateToSend[i.offset.description] = Double(i.element)
      }
      copterState.updateSensors(stateToSend)
      readState = 0
    }
    objc_sync_exit(self)
  }
  
  func reset() {
    os_log("ZZZZ reset")
  }
  
  func parseSensorReading(_ data: Data?) -> [String: Double] {
    /* var result: [String: Double] = [:]
    if let data = data {
      os_log("eval count %d", data.count)
      for i in 0..<data.count {
        os_log("XXXXXX %c -- %u", data[i], data[i])
      } */
      /*
       let prefix = String(data: data.prefix(3), encoding: String.Encoding.utf8)!
       if prefix != "$M>" {
       os_log("unexpected prefix %@", prefix)
       return result
       }
       
       let numBytes = data[3]
       let cmd = data[3 ... Int(3+numBytes)]
       os_log("expecting command size %d", numBytes)
       
       var i = 0
       result.updateValue(CentralBluetoothClient.read2BFractional(from: cmd, at: i) * 0.1,
       forKey: CentralBluetoothClient.ROLL)
       i += 2
       result.updateValue(CentralBluetoothClient.read2BFractional(from: cmd, at: i) * 0.1,
       forKey: CentralBluetoothClient.PITCH)
       i += 2
       result.updateValue(CentralBluetoothClient.read2BFractional(from: cmd, at: i) * 0.1,
       forKey: CentralBluetoothClient.YAW)
       i += 2
       result.updateValue(CentralBluetoothClient.read4BFractional(from: cmd, at: i) * 0.01,
       forKey: CentralBluetoothClient.ALTITUDE)
       i += 4
       result.updateValue(CentralBluetoothClient.read2BFractional(from: cmd, at: i) * 0.01,
       forKey: CentralBluetoothClient.VOLTS)
       i += 2
       result.updateValue(CentralBluetoothClient.read2BFractional(from: cmd, at: i) * 0.001,
       forKey: CentralBluetoothClient.SPEEDZ)
       i += 2
       let checksum = UInt8(data[i+3])
       os_log("read checksum %d", checksum)
       let sum = cmd.reduce(UInt8(0)) {
       UInt8($0) ^ ($1 & 0xFF)
       }
       */
      
      // os_log("computed checksum %d", sum)
    /*
    }
    os_log("read sensors %@", result)
    return result
     */
    return [:]
  }
  
  static func readData(from: Data) -> UInt32 {
    var sum: UInt32 = 0
    for i in 0 ..< from.count {
      let b = from[i] & 0xff
      sum += UInt32(b << (i * 8))
    }
    return sum
  }
  
  static func read2BFractional(from: Data, at: Int) -> Double {
    return Double(UInt(from[at]&0xff) + UInt((from[at+1])<<8))
  }
  
  static func read4BFractional(from: Data, at: Int) -> Double {
    var sum: UInt32 = UInt32(from[at]&0xff)
    sum += UInt32((from[at+1]&0xff)<<8)
    sum += UInt32((from[at+2]&0xff)<<16)
    sum += UInt32((from[at+3]&0xff)<<24)
    return Double(sum)
  }
  
}

//
//  StreamCommand.swift
//  BreakThePony
//
//  Created by Jonathan Bredin on 2/8/18.
//  Copyright © 2018 Jonathan Bredin. All rights reserved.
//

import CoreBluetooth
import Foundation
import os.log

class StreamCommand : CommandExecutor {
  static private var runId = 0
  private let copterState: CopterStateServer
  let ioF: Int32
  
  init(copterState: CopterStateServer, f: Int32) {
    self.copterState = copterState
    self.ioF = f
  }
  
  func run() {
    var thisTag: String
    objc_sync_enter(StreamCommand.runId)
    thisTag = "stream-" + StreamCommand.runId.description
    StreamCommand.runId += 1
    objc_sync_exit(StreamCommand.runId)
    
    func f (sensorReading: [String: Double]) -> Void {
      do {
        try SensorDriverServer.sendToken(fd: self.ioF, token: GetCommand.marshallState(sensorReading))
      } catch {
        copterState.unsubscribeSensors(tag: thisTag)
        os_log("terminating stream: %@", error.localizedDescription)
        close(self.ioF)
      }
    }

    copterState.subscribeSensors(tag: thisTag, callback: f)
  }
}

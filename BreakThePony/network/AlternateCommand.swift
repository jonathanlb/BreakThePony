//
//  AlternateCommand.swift
//  BreakThePony
//
//  Created by Jonathan Bredin on 1/29/18.
//  Copyright © 2018 Jonathan Bredin. All rights reserved.
//

import Foundation
import os.log

class AlternateCommand : CommandExecutor {
  private let copterState: CopterStateServer
  let ioF: Int32
  
  init(copterState: CopterStateServer, f: Int32) {
    self.copterState = copterState
    ioF = f
  }
  
  func run() {
    defer {
      os_log("terminating alternate on %d", ioF)
      close(ioF)
    }
    let get = GetCommand(copterState: copterState, f: ioF, closeOnRead: false)
    let put = PutCommand(copterState: copterState, f: ioF, closeOnPut: false)
    while true {
      get.run()
      put.run()
    }
  }
}

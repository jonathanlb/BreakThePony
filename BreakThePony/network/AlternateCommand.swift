//
//  AlternateCommand.swift
//  BreakThePony
//
//  Created by Jonathan Bredin on 1/29/18.
//  Copyright © 2018 Jonathan Bredin. All rights reserved.
//

import Foundation

class AlternateCommand : CommandExecutor {
  private let copterState: CopterStateServer
  let ioF: Int32
  
  init(copterState: CopterStateServer, f: Int32) {
    self.copterState = copterState
    ioF = f
  }
  
  func run() {
    let get = GetCommand(copterState: copterState, f: ioF)
    let put = PutCommand(copterState: copterState, f: ioF)
    while true {
      get.run()
      put.run() // XXX allow termination
    }
  }
}

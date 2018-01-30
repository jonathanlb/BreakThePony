//
//  main.swift
//  BreakThePony
//
//  Created by Jonathan Bredin on 1/16/18.
//  Copyright © 2018 Jonathan Bredin. All rights reserved.
//

import Foundation

let copterState = SimpleCopterStateServer()
let btControl = CentralBluetoothClient(copterState: copterState)
btControl.start()

let sensors = SensorDriverServer(copterState: copterState)
do {
  try sensors.run()
  print("connected")
  
  defer {
    btControl.stop()
  }
} catch SensorDriverError.network {
  exit(-1)
}

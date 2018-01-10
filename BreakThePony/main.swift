//
//  main.swift
//  BreakThePony
//
//  Created by Jonathan Bredin on 1/9/18.
//  Copyright © 2018 Jonathan Bredin. All rights reserved.
//

import Foundation

let client = CentralBluetoothClient()
client.start()
sleep(3 * 60)
client.stop()

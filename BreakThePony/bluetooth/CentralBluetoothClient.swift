//
//  CentralBluetoothClient.swift
//  BreakThePony
//
//  Created by Jonathan Bredin on 1/9/18.
//  Copyright © 2018 Jonathan Bredin. All rights reserved.
//

import CoreBluetooth

class CentralBluetoothClient : NSObject {
  // Crazepony characteristics and services from github.... not useful?
  let notifyCharId = CBUUID(string: "0000ffe1-0000-1000-8000-00805f9b34fb")
  let serviceId =    CBUUID(string: "0000ffe0-0000-1000-8000-00805f9b34fb")
  
  private let copterState: CopterStateServer
  private var centralManager: CBCentralManager!
  private var quadcopterPeripheral: CBPeripheral!
  private var serviceIds: [CBUUID] = []
  private var characteristics: Set<CBCharacteristic> = []
  
  let bluetoothScanOptions = [
    CBCentralManagerScanOptionAllowDuplicatesKey: false]

  init(copterState: CopterStateServer) {
    self.copterState = copterState
  }
  
  func connect(peripheral: CBPeripheral) {
    NSLog("connecting %@", peripheral)
    quadcopterPeripheral = peripheral
    centralManager.connect(quadcopterPeripheral)
  }
  
  func disconnect() {
    if quadcopterPeripheral != nil {
      NSLog("disconnecting %@", quadcopterPeripheral)
      centralManager.cancelPeripheralConnection(quadcopterPeripheral)
      quadcopterPeripheral = nil
    }
  }
  
  func isQuadcopter(peripheral: CBPeripheral) -> Bool {
    return peripheral.name!.starts(with: "Crazepony")
  }
  
  func isScanning() -> Bool {
    return centralManager != nil && centralManager.isScanning
  }
  
  func start() {
    NSLog("Bluetooth start")
    let bt_queue = DispatchQueue(label: "BT_queue")
    centralManager = CBCentralManager(delegate: self, queue: bt_queue)
  }
  
  func stop() {
    if centralManager != nil {
      disconnect()
      centralManager.stopScan()
      centralManager = nil
      NSLog("Bluetooth stopped")
    }
  }
}

extension CentralBluetoothClient : CBCentralManagerDelegate {
  func centralManager(_ central: CBCentralManager,
                      didDiscover peripheral: CBPeripheral,
                      advertisementData: [String : Any],
                      rssi RSSI: NSNumber)
  {
    NSLog("centralManager discovered %@ with %@ rssi %@",
          peripheral, advertisementData, RSSI)
    if isQuadcopter(peripheral: peripheral) && peripheral.state != .connected {
      if let advertServices = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? NSArray {
        for serviceId in advertServices {
          if let serviceId = serviceId as? CBUUID {
            if !serviceIds.contains(serviceId) {
              serviceIds.append(serviceId)
            }
          }
        }
      } else {
        NSLog("no service advert %@", advertisementData[CBAdvertisementDataServiceUUIDsKey].debugDescription)
      }
      connect(peripheral: peripheral)
    }
  }
  
  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    NSLog("connected %@", peripheral)
    quadcopterPeripheral = peripheral
    peripheral.delegate = self // CopterBluetoothController()
    
    if peripheral.services != nil {
      NSLog("looking for advertized services %@", peripheral.services.debugDescription)
      peripheral.delegate?.peripheral!(peripheral, didDiscoverServices: nil)
    } else {
      NSLog("looking for services %@", serviceIds)
      peripheral.discoverServices(serviceIds) // none
    }
  }
  
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    switch (central.state) {
    case .poweredOff:
      NSLog("Powered Off")
    case .poweredOn:
      NSLog("Powered On")
      centralManager.scanForPeripherals(
        withServices: nil, options: bluetoothScanOptions)
      NSLog("scanning: %@", centralManager.isScanning.description)
    case .unauthorized:
      NSLog("Unauthorized")
    case .unknown:
      NSLog("Unknown")
    case .unsupported:
      NSLog("Unsupported")
    default:
      NSLog("Default")
    }
  }
  
  func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    NSLog("disconnected")
  }
  
  /*
  func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
    NSLog("will restore")
  }*/
  
  func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
    NSLog("failed")
  }
}

/*
 * Handle updates to reading and writing values to quad copter.
 * Do not separate from CentralBluetoothClient, as doing so breaks
 * callbacks?
 */
extension CentralBluetoothClient : CBPeripheralDelegate {
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    for service in peripheral.services! {
      NSLog("discovered service %@", service)
      peripheral.discoverCharacteristics(nil, for: service)
    }
  }
  
  func peripheral(_ peripheral: CBPeripheral,
                  didDiscoverCharacteristicsFor service: CBService,
                  error: Error?)
  {
    for characteristic in service.characteristics! {
      NSLog("characteristic %@ : %@", characteristic, characteristic.value?.description ?? "???")
      characteristics.insert(characteristic)
      peripheral.readValue(for: characteristic)
    }
  }
  
  func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
    NSLog("peripheral ready")
  }
  
  func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
    NSLog("discovered descriptors")
  }
  
  func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
    NSLog("update name")
  }
  
  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
    NSLog("updateValue desc")
  }
  
  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    NSLog("update %@ : %@", characteristic, characteristic.value?.description ?? "???")
  }
  
  func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
    NSLog("update notify statis")
  }
  
  func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
    NSLog("included services")
  }
  
  func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
    NSLog("did write value for descriptor")
  }
  
  func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
    NSLog("did write value for characteristic")
  }
  
  func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {
    NSLog("did open")
  }
}

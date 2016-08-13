//
//  ViewController.swift
//  BluetoothLED
//
//  Created by Mathias Köhnke on 12/08/16.
//  Copyright © 2016 Mathias Köhnke. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    struct Static {
        private static let ServiceUUID = CBUUID(string: "19B10001-E8F2-537E-4F6C-D104768A1214")
    }
    
    private var centralManager : CBCentralManager!
    private var peripheral : CBPeripheral?
    private var characteristic : CBCharacteristic?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    
    // MARK: CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        if central.state == .PoweredOff {
            print("CoreBluetooth BLE hardware is powered off");
        }
        else if central.state == .PoweredOn {
            print("CoreBluetooth BLE hardware is powered on and ready");
            centralManager.scanForPeripheralsWithServices(nil, options: nil)
        }
        else if central.state == .Unauthorized {
            print("CoreBluetooth BLE state is unauthorized");
        }
        else if central.state == .Unknown {
            print("CoreBluetooth BLE state is unknown");
        }
        else if central.state == .Unsupported {
            print("CoreBluetooth BLE hardware is unsupported on this platform");
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        if let peripheralName = peripheral.name where String(peripheralName.characters.suffix(4)) == "DAF5" {
            print("Connecting to peripheral \(peripheralName) ...")
            self.peripheral = peripheral
            central.connectPeripheral(peripheral, options: nil)
        }
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("Failed to connect to peripheral \(peripheral.identifier.UUIDString).")
        cleanup()
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("Did disconnect from peripheral \(peripheral.identifier.UUIDString).")
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("Did connect to peripheral \(peripheral.name ?? peripheral.identifier.UUIDString).")
        central.stopScan()
        print("Scanning stopped.")
        peripheral.delegate = self
        peripheral.discoverServices([Static.ServiceUUID])
    }
    
    func cleanup() {
        
        if let services = peripheral?.services {
            for service in services {
                if let characteristics = service.characteristics {
                    for characteristic in characteristics {
                        if characteristic.UUID.isEqual(Static.ServiceUUID) {
                            if characteristic.isNotifying {
                                peripheral?.setNotifyValue(false, forCharacteristic: characteristic)
                                return
                            }
                        }
                    }
                }
            }
        }
        
        if let peripheral = peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    // MARK: CBPeripheralDelegate
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        if let error = error {
            print("Error discovering service: \(error.localizedDescription)")
            cleanup()
            return
        }
        
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics([Static.ServiceUUID], forService: service)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        if let error = error {
            print("Error discovering characteristics for service \(service): \(error.localizedDescription)")
            cleanup()
            return
        }
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.UUID.isEqual(Static.ServiceUUID) {
                    peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                    self.characteristic = characteristic
                }
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if let error = error {
            print("Error updating value for characteristic \(characteristic): \(error.localizedDescription)")
            return
        }
        
        print(characteristic.value)
    }
    
    // MARK: Actions
    
    @IBAction func buttonTouched(sender: AnyObject) {
        var value: Int = 1
        let data = NSData(bytes: &value, length: sizeof(Int))
        
        if let peripheral = peripheral, characteristic = characteristic {
            peripheral.writeValue(data, forCharacteristic: characteristic, type: CBCharacteristicWriteType.WithoutResponse)
        }
    }
}


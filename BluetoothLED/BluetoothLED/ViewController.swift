//
//  ViewController.swift
//  BluetoothLED
//
//  Created by Mathias Köhnke on 12/08/16.
//  Copyright © 2016 Mathias Köhnke. All rights reserved.
//

import UIKit
import Foundation
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    struct Static {
        private static let ServiceUUID = CBUUID(string: "19B10000-E8F2-537E-4F6C-D104768A1214")
        private static let CharacteristicUUID = CBUUID(string: "19B10001-E8F2-537E-4F6C-D104768A1214")
    }
    
    @IBOutlet weak var button : UIButton!
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
        if let peripheralName = peripheral.name where peripheralName.uppercaseString.hasPrefix("GENUINO 101") {
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
        self.peripheral?.delegate = self
        self.peripheral?.discoverServices([Static.ServiceUUID])
    }
    
    func cleanup() {
        
        if let services = peripheral?.services {
            for service in services {
                if let characteristics = service.characteristics {
                    for characteristic in characteristics {
                        if characteristic.UUID.isEqual(Static.CharacteristicUUID) {
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
                peripheral.discoverCharacteristics([Static.CharacteristicUUID], forService: service)
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
                if characteristic.UUID.isEqual(Static.CharacteristicUUID) {
                    peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                    self.characteristic = characteristic
                    print("Subscribed to characteristic: \(characteristic)")
                    updateButton()
                }
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if let error = error {
            print("Error updating value for characteristic \(characteristic): \(error.localizedDescription)")
            return
        }
        
        print("Value changed to \(getValueFromCharacteristic())")
        updateButton()
    }
    
    // MARK: Actions
    
    @IBAction func buttonTouched(sender: AnyObject) {
        var value = getValueFromCharacteristic() == NSInteger(0) ? NSInteger(1) : NSInteger(0)
        let data = NSData(bytes: &value, length: 1)
        
        if let peripheral = peripheral, characteristic = characteristic {
            peripheral.writeValue(data, forCharacteristic: characteristic, type: CBCharacteristicWriteType.WithResponse)
            peripheral.readValueForCharacteristic(characteristic)
        }
    }
    
    func getValueFromCharacteristic() -> NSInteger {
        if let data = self.characteristic?.value {
            var result: NSInteger = 0
            data.getBytes(&result, length: 1)
            return result
        }
        return NSInteger(0)
    }
    
    func updateButton() {
        if getValueFromCharacteristic() == 0 {
            button.setTitle("Turn On", forState: .Normal)
        } else {
            button.setTitle("Turn Off", forState: .Normal)
        }
    }
}


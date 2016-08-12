//
//  ViewController.swift
//  BluetoothLED
//
//  Created by Mathias Köhnke on 12/08/16.
//  Copyright © 2016 Mathias Köhnke. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate {

    private var centralManager : CBCentralManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //let uuid = CBUUID(string: "19B10000-E8F2-537E-4F6C-D104768A1214")
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        centralManager.scanForPeripheralsWithServices(nil, options: nil)
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        if central.state == .PoweredOff {
            print("CoreBluetooth BLE hardware is powered off");
        }
        else if central.state == .PoweredOn {
            print("CoreBluetooth BLE hardware is powered on and ready");
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
        print(peripheral)
    }
}


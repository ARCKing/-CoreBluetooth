//
//  ViewController.swift
//  BT
//
//  Created by macos on 2019/4/16.
//  Copyright © 2019 cqc. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        TTBluetoothManger.share.bluetoohStar()

    }

    @IBOutlet weak var lb: UILabel!
    
    @IBAction func action(_ sender: Any) {
        
        TTBluetoothManger.share.deviceStartWriteValue(TTBluetoothManger.share.currentCharacteristic_02_01!)

    }
    
}


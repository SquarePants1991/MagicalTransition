//
//  PresentedViewController.swift
//  BrokenGlassEffect
//
//  Created by wang yang on 2017/8/22.
//  Copyright © 2017年 ocean. All rights reserved.
//

import Foundation
import UIKit

class PresentedViewController: UIViewController {
    static func instance() -> UIViewController {
        return UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "presented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func closeButtonClicked(_ sender: Any) {
        self.dismiss(animated: true) {
            
        }
    }
}

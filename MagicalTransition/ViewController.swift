//
//  ViewController.swift
//  BrokenGlassEffect
//
//  Created by wang yang on 2017/8/21.
//  Copyright © 2017年 ocean. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIViewControllerTransitioningDelegate {

    @IBOutlet weak var brokenGlassView: MagicalEffectView!
    let brokenGlassAnimator: MagicalTransitionAnimator = MagicalTransitionAnimator.init()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func brokeClicked(_ sender: Any) {
        let vc = PresentedViewController.instance()
        vc.transitioningDelegate = self
        self.present(vc, animated: true) {
            
        }
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return brokenGlassAnimator
    }
}


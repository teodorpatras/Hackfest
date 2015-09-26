//
//  ViewController.swift
//  PayCode
//
//  Created by Teodor Patras on 26/09/15.
//  Copyright © 2015 Teodor Patras. All rights reserved.
//

import UIKit
import SVProgressHUD
import FontAwesomeKit

class ViewController: UIViewController, CardIOPaymentViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        CardIOUtilities.preload()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        SVProgressHUD.showSuccessWithStatus("Hooray!")
    }

    @IBAction func action() {
        let cardIOVC = CardIOPaymentViewController(paymentDelegate: self)
        cardIOVC.modalPresentationStyle = .FormSheet
        cardIOVC.view.frame = self.view.bounds
        for view in cardIOVC.view.subviews {
            view.frame = self.view.bounds
        }
        presentViewController(cardIOVC, animated: true, completion: nil)
    }
    
    
    func userDidCancelPaymentViewController(paymentViewController: CardIOPaymentViewController!) {
        print("User canceled!")
    }
    
    func userDidProvideCreditCardInfo(cardInfo: CardIOCreditCardInfo!, inPaymentViewController paymentViewController: CardIOPaymentViewController!) {
        if let info = cardInfo {
            let str = NSString(format: "Received card info.\n Number: %@\n expiry: %02lu/%lu\n cvv: %@.", info.cardNumber, info.expiryMonth, info.expiryYear, info.cvv)
            print(str)
        }
    }
}


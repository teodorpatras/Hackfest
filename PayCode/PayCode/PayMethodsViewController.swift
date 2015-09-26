//
//  PayMethodsViewController.swift
//  PayCode
//
//  Created by Teodor Patras on 26/09/15.
//  Copyright © 2015 Teodor Patras. All rights reserved.
//

import UIKit
import TGLStackedViewController
import FontAwesomeKit

class PayMethodsViewController: TGLStackedViewController, CardIOPaymentViewControllerDelegate,PayPalFuturePaymentDelegate {
    
    weak var addButton : UIButton!
    
    override var exposedItemIndexPath : NSIndexPath?{
        didSet{
            let enabled = exposedItemIndexPath == nil
            UIView.animateWithDuration(0.25, animations: { () -> Void in
                self.addButton.alpha = enabled ? 1 : 0
                }) { _ -> Void in
                self.addButton.enabled = enabled
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        CardIOUtilities.preload()
        PayPalMobile.preconnectWithEnvironment(PayPalEnvironmentSandbox)
    }
    
    // MARK: - CardIO -
    
    func userDidCancelPaymentViewController(paymentViewController: CardIOPaymentViewController!) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func userDidProvideCreditCardInfo(cardInfo: CardIOCreditCardInfo!, inPaymentViewController paymentViewController: CardIOPaymentViewController!) {
        if let info = cardInfo {
            let str = NSString(format: "Received card info.\n Number: %@\n expiry: %02lu/%lu\n cvv: %@.", info.cardNumber, info.expiryMonth, info.expiryYear, info.cvv)
            print(str)
        }
    }
    
    // MARK: - CollectionView -
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("paymentCell", forIndexPath: indexPath) as! PaymentCell
        cell.refresh()
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }
    
    // MARK: - PayPalFuturePayment -
    
    func payPalFuturePaymentDidCancel(futurePaymentViewController: PayPalFuturePaymentViewController!) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func payPalFuturePaymentViewController(futurePaymentViewController: PayPalFuturePaymentViewController!, didAuthorizeFuturePayment futurePaymentAuthorization: [NSObject : AnyObject]!) {
        print("-----------------\n\n\(futurePaymentAuthorization)\n\n--------------------")
        print(PayPalMobile.clientMetadataID())
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - Callbacks -
    
    func addPayment() {

        let controller = UIAlertController(title: "Choose payment method", message: nil, preferredStyle: .ActionSheet)
        let payPalAction = UIAlertAction(title: "PayPal", style: .Default) { _ -> Void in

            let configuration = PayPalConfiguration()
            configuration.merchantName = "PayCode"
            configuration.merchantPrivacyPolicyURL = NSURL(string: "http://www.google.com")
            configuration.merchantUserAgreementURL = NSURL(string: "http://www.google.com")
            let controller = PayPalFuturePaymentViewController(configuration: configuration, delegate: self)
            self.presentViewController(controller, animated: true, completion: nil)
        }

        let cardAction = UIAlertAction(title: "Credit card", style: .Default) { _ -> Void in
            // card
            let cardIOVC = CardIOPaymentViewController(paymentDelegate: self)
            cardIOVC.modalPresentationStyle = .FormSheet
            cardIOVC.view.frame = self.view.bounds
            for view in cardIOVC.view.subviews {
                view.frame = self.view.bounds
            }
            
            self.presentViewController(cardIOVC, animated: true) { () -> Void in
                UIApplication.sharedApplication().statusBarStyle = .LightContent
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { _ -> Void in
            
        }
        
        controller.addAction(payPalAction)
        controller.addAction(cardAction)
        controller.addAction(cancelAction)
        self.presentViewController(controller, animated: true, completion: nil)
                controller.view.tintColor = UIColor(hue:0, saturation:0, brightness:0.44, alpha:1)
    }
    
    // MARK: - Helpers -
    
    func configureUI() {
        configureStackView()
        
        let screenSize = UIScreen.mainScreen().bounds.size
        let y : CGFloat = 30
        
        let label = UILabel(frame: CGRectMake(10, y, 250, 70))
        label.backgroundColor =  UIColor.clearColor()
        label.textColor = UIColor.whiteColor()
        label.font = AppTheme.font(20)
        label.text = "Your payment methods"
        
        let button = UIButton(frame: CGRectMake(screenSize.width - 55, y + 10, 50, 50))
        button.addTarget(self, action: "addPayment", forControlEvents: .TouchUpInside)
        let icon = FAKFontAwesome.plusSquareOIconWithSize(25)
        icon.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor())
        
        
        button.setImage(icon.imageWithSize(CGSizeMake(50, 50)), forState: .Normal)
        self.view.addSubview(button)
        self.addButton = button
        self.view.insertSubview(label, belowSubview: self.collectionView!)
        
        
        self.collectionView?.backgroundColor = UIColor.clearColor()
        
        self.collectionView?.registerClass(PaymentCell.self, forCellWithReuseIdentifier: "paymentCell")
    }
    
    func configureStackView() {
        // Set to NO to prevent a small number
        // of cards from filling the entire
        // view height evenly and only show
        // their -topReveal amount
        //
        self.stackedLayout.fillHeight = true;
        
        // Set to NO to prevent a small number
        // of cards from being scrollable and
        // bounce
        //
        self.stackedLayout.alwaysBounce = true;
        
        // Set to NO to prevent unexposed
        // items at top and bottom from
        // being selectable
        //
        self.unexposedItemsAreSelectable = true;
        
        let size = CGSizeMake(0.0, 250.0)
        
        self.exposedItemSize = size
        self.stackedLayout.itemSize = size
        self.exposedPinningMode = .All;
        self.exposedTopOverlap = 50.0;
        self.exposedBottomOverlap = 50.0;
        
        self.exposedBottomOverlapCount = 4
        
        self.exposedTopPinningCount = 2
        self.exposedBottomPinningCount = 5
        
        self.collectionView?.contentInset = UIEdgeInsetsMake(100, 0, 0, 0)
    }
}

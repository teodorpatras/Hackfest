//
//  PayMethodsViewController.swift
//  PayCode
//
//  Created by Teodor Patras on 26/09/15.
//  Copyright © 2015 Teodor Patras. All rights reserved.
//

import CoreData
import UIKit
import TGLStackedViewController
import FontAwesomeKit

class PayMethodsViewController: TGLStackedViewController, CardIOPaymentViewControllerDelegate,PayPalFuturePaymentDelegate, NSFetchedResultsControllerDelegate {
    
    weak var addButton : UIButton!
    
    lazy var fetchedResultController:NSFetchedResultsController = {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        let sortDescriptor  = NSSortDescriptor(key: "identifier", ascending: true)
        let fetchRequest = NSFetchRequest(entityName: "Payment")
        fetchRequest.fetchBatchSize = 20
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let fetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: appDelegate.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultController.delegate = self
        return fetchedResultController
    }()
    
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
        
        try! self.fetchedResultController.performFetch()
        
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let payment = NSEntityDescription.insertNewObjectForEntityForName("Payment", inManagedObjectContext: appDelegate.managedObjectContext) as! Payment
        payment.name = "Michal Hernas"
        payment.type = "visa"
        payment.identifier = "4111 1111 1111 1111"
        payment.validUntill = "02/19"
        
        
        let payment1 = NSEntityDescription.insertNewObjectForEntityForName("Payment", inManagedObjectContext: appDelegate.managedObjectContext) as! Payment
        payment1.name = "Bartosz Hernas"
        payment1.type = "mastercard"
        payment1.identifier = "4111 2335 6558 5444"
        payment1.validUntill = "11/18"
        
        let payment2 = NSEntityDescription.insertNewObjectForEntityForName("Payment", inManagedObjectContext: appDelegate.managedObjectContext) as! Payment
        payment2.name = "Bartosz Hernas"
        payment2.type = "paypal"
        payment2.identifier = "bartosz@hernas.pl"
        payment2.validUntill = "11/18"
        
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
        cell.configureWithModel(self.fetchedResultController.objectAtIndexPath(indexPath) as! Payment)
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let section:NSFetchedResultsSectionInfo = self.fetchedResultController.sections![section]
        return section.numberOfObjects
    }
    
    // MARK: - PayPalFuturePayment -
    
    func payPalFuturePaymentDidCancel(futurePaymentViewController: PayPalFuturePaymentViewController!) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func payPalFuturePaymentViewController(futurePaymentViewController: PayPalFuturePaymentViewController!, didAuthorizeFuturePayment futurePaymentAuthorization: [NSObject : AnyObject]!) {
        print("-----------------\n\n\(futurePaymentAuthorization)\n\n--------------------")
    }
    
    func payPalFuturePaymentViewController(futurePaymentViewController: PayPalFuturePaymentViewController!, willAuthorizeFuturePayment futurePaymentAuthorization: [NSObject : AnyObject]!, completionBlock: PayPalFuturePaymentDelegateCompletionBlock!) {
        completionBlock()
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

        self.collectionView?.registerNib(UINib(nibName: "PaymentCell", bundle: nil), forCellWithReuseIdentifier: "paymentCell")
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
    
    
    // I just implemented that with Swift. So I would like to share my implementation.
    // First initialise an array of NSBlockOperations:
    var blockOperations: [NSBlockOperation] = []
    
    
    // In the did change object method:
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        if type == NSFetchedResultsChangeType.Insert {
            print("Insert Object: \(newIndexPath)")
            
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.insertItemsAtIndexPaths([newIndexPath!])
                    }
                    })
            )
        }
        else if type == NSFetchedResultsChangeType.Update {
            print("Update Object: \(indexPath)")
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadItemsAtIndexPaths([indexPath!])
                    }
                    })
            )
        }
        else if type == NSFetchedResultsChangeType.Move {
            print("Move Object: \(indexPath)")
            
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.moveItemAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
                    }
                    })
            )
        }
        else if type == NSFetchedResultsChangeType.Delete {
            print("Delete Object: \(indexPath)")
            
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.deleteItemsAtIndexPaths([indexPath!])
                    }
                    })
            )
        }
    }
    
    // In the did change section method:
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        
        if type == NSFetchedResultsChangeType.Insert {
            print("Insert Section: \(sectionIndex)")
            
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.insertSections(NSIndexSet(index: sectionIndex))
                    }
                    })
            )
        }
        else if type == NSFetchedResultsChangeType.Update {
            print("Update Section: \(sectionIndex)")
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadSections(NSIndexSet(index: sectionIndex))
                    }
                    })
            )
        }
        else if type == NSFetchedResultsChangeType.Delete {
            print("Delete Section: \(sectionIndex)")
            
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.deleteSections(NSIndexSet(index: sectionIndex))
                    }
                    })
            )
        }
    }
    
    // And finally, in the did controller did change content method:
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        collectionView!.performBatchUpdates({ () -> Void in
            for operation: NSBlockOperation in self.blockOperations {
                operation.start()
            }
            }, completion: { (finished) -> Void in
                self.blockOperations.removeAll(keepCapacity: false)
        })
    }
    
    // I personally added some code in the deinit method as well, in order to cancel the operations when the ViewController is about to get deallocated:
    deinit {
        // Cancel all block operations when VC deallocates
        for operation: NSBlockOperation in blockOperations {
            operation.cancel()
        }
        
        blockOperations.removeAll(keepCapacity: false)
    }
}

//
//  PayMethodsViewController.swift
//  PayCode
//
//  Created by Teodor Patras on 26/09/15.
//  Copyright © 2015 Teodor Patras. All rights reserved.
//

import CoreData
import UIKit
import SVProgressHUD
import TGLStackedViewController
import FontAwesomeKit
import Alamofire

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
        self.view.backgroundColor = UIColor.clearColor()
        configureUI()
        CardIOUtilities.preload()
        PayPalMobile.preconnectWithEnvironment(PayPalEnvironmentSandbox)
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: .Slide)
        
        try! self.fetchedResultController.performFetch()
        
        if self.fetchedResultController.sections![0].numberOfObjects == 0 {
            SVProgressHUD.show()
            
            let request = NSMutableURLRequest(URL: NSURL(string: "http://ohf.hern.as/payments/")!)
            request.HTTPMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            Alamofire.request(request).responseJSON { (request, response, result) -> Void in
                SVProgressHUD.dismiss()
                if let array = result.value as? [[String : AnyObject]] {
                    for dict in array {
                        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                        let payment = NSEntityDescription.insertNewObjectForEntityForName("Payment", inManagedObjectContext: appDelegate.managedObjectContext) as! Payment
                        
                        payment.name = (dict["data"] as? [String: AnyObject])?["name"] as? String ?? "Teodor Patras"
                        payment.id = dict["id"] as! Int
                        
                        payment.type = (dict["card_type"] as? String)?.lowercaseString ?? "paypal"
                        
                        payment.identifier = (dict["data"] as? [String: AnyObject])?["email"] as? String ?? ((dict["data"] as? [String: AnyObject])?["number"] as? String)!.curatedString()
                        
                        if let str = (dict["data"] as? [String: AnyObject])?["expiration"] as? String {
                            payment.validUntill = str
                        }
                    }
                }
            }
            
        }
        
        self.collectionView?.reloadData()
    }
    
    // MARK: - CardIO -
    
    func userDidCancelPaymentViewController(paymentViewController: CardIOPaymentViewController!) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func userDidProvideCreditCardInfo(cardInfo: CardIOCreditCardInfo!, inPaymentViewController paymentViewController: CardIOPaymentViewController!) {
        if let info = cardInfo {
            
            // 5173 3709 8453 3122
            
            
            let str = "\(info.expiryYear)"
            let year = str.substringFromIndex(2)
            let expiration = "\(info.expiryMonth)/\(year)"
            
            let dict = ["number" : info.cardNumber, "expiration" : expiration, "cvv" : info.cvv]
            
            
            let request = NSMutableURLRequest(URL: NSURL(string: "http://ohf.hern.as/payments/card/")!)
            request.HTTPMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            try! request.HTTPBody = NSJSONSerialization.dataWithJSONObject(dict, options: [])
            
            SVProgressHUD.show()
            Alamofire.request(request).responseJSON { (request, response, result) -> Void in
                SVProgressHUD.dismiss()
                if let dict = result.value as? [String : AnyObject] {
                    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                    let payment = NSEntityDescription.insertNewObjectForEntityForName("Payment", inManagedObjectContext: appDelegate.managedObjectContext) as! Payment
                    payment.name = "Teodor Patras"
                    payment.id = dict["id"] as! Int
                    payment.type = (dict["card_type"] as! String).lowercaseString
                    payment.identifier = info.redactedCardNumber
                    payment.validUntill = expiration
                }
            }
        }
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - CollectionView -
    var flag = true
    override func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        
        if flag == true {
            
            cell.transform = CGAffineTransformMakeScale(0.00001, 0.00001)
            
            UIView.animateWithDuration(0.75, delay: Double(0.2) * Double(indexPath.item + 1), usingSpringWithDamping: 0.7, initialSpringVelocity: 0.1, options: .CurveEaseInOut, animations: { () -> Void in
                cell.transform = CGAffineTransformIdentity
                }, completion: nil)
            
            if indexPath.row == 2 {
                flag = false
            }
        }
    }
    
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
        
        let clientCode = (futurePaymentAuthorization["response"] as! [String : AnyObject])["code"] as! String
        let dict = ["authorization_code" : clientCode, "correlation_id" : PayPalMobile.clientMetadataID()]
        
        
        let request = NSMutableURLRequest(URL: NSURL(string: "http://ohf.hern.as/payments/paypal/")!)
        request.HTTPMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try! request.HTTPBody = NSJSONSerialization.dataWithJSONObject(dict, options: [])
        
        SVProgressHUD.show()
        Alamofire.request(request).responseJSON { (request, response, result) -> Void in
            SVProgressHUD.dismiss()
            if let dict = (result.value as? [String : AnyObject])?["data"] as? [String : AnyObject] {
                let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                let payment = NSEntityDescription.insertNewObjectForEntityForName("Payment", inManagedObjectContext: appDelegate.managedObjectContext) as! Payment
                payment.name = dict["name"] as! String
                payment.id = (result.value as? [String : AnyObject])?["id"] as! Int
                payment.type = "paypal"
                payment.identifier = dict["email"] as! String
            }   
        }
        
        self.dismissViewControllerAnimated(true, completion: nil)
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
                controller.view.tintColor = UIColor.blackColor()
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
        
        let size = CGSizeMake(0, 260.0)
        
        self.stackedLayout.topReveal = 200.0
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
    
    
//    // I just implemented that with Swift. So I would like to share my implementation.
//    // First initialise an array of NSBlockOperations:
//    var blockOperations: [NSBlockOperation] = []
//    
//    
//    // In the did change object method:
//    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
//        
//        if type == NSFetchedResultsChangeType.Insert {
//            print("Insert Object: \(newIndexPath)")
//            
//            blockOperations.append(
//                NSBlockOperation(block: { [weak self] in
//                    if let this = self {
//                        this.collectionView!.insertItemsAtIndexPaths([newIndexPath!])
//                    }
//                    })
//            )
//        }
//        else if type == NSFetchedResultsChangeType.Update {
//            print("Update Object: \(indexPath)")
//            blockOperations.append(
//                NSBlockOperation(block: { [weak self] in
//                    if let this = self {
//                        this.collectionView!.reloadItemsAtIndexPaths([indexPath!])
//                    }
//                    })
//            )
//        }
//        else if type == NSFetchedResultsChangeType.Move {
//            print("Move Object: \(indexPath)")
//            
//            blockOperations.append(
//                NSBlockOperation(block: { [weak self] in
//                    if let this = self {
//                        this.collectionView!.moveItemAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
//                    }
//                    })
//            )
//        }
//        else if type == NSFetchedResultsChangeType.Delete {
//            print("Delete Object: \(indexPath)")
//            
//            blockOperations.append(
//                NSBlockOperation(block: { [weak self] in
//                    if let this = self {
//                        this.collectionView!.deleteItemsAtIndexPaths([indexPath!])
//                    }
//                    })
//            )
//        }
//    }
//    
//    // In the did change section method:
//    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
//        
//        if type == NSFetchedResultsChangeType.Insert {
//            print("Insert Section: \(sectionIndex)")
//            
//            blockOperations.append(
//                NSBlockOperation(block: { [weak self] in
//                    if let this = self {
//                        this.collectionView!.insertSections(NSIndexSet(index: sectionIndex))
//                    }
//                    })
//            )
//        }
//        else if type == NSFetchedResultsChangeType.Update {
//            print("Update Section: \(sectionIndex)")
//            blockOperations.append(
//                NSBlockOperation(block: { [weak self] in
//                    if let this = self {
//                        this.collectionView!.reloadSections(NSIndexSet(index: sectionIndex))
//                    }
//                    })
//            )
//        }
//        else if type == NSFetchedResultsChangeType.Delete {
//            print("Delete Section: \(sectionIndex)")
//            
//            blockOperations.append(
//                NSBlockOperation(block: { [weak self] in
//                    if let this = self {
//                        this.collectionView!.deleteSections(NSIndexSet(index: sectionIndex))
//                    }
//                    })
//            )
//        }
//    }
//    
    // And finally, in the did controller did change content method:
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        collectionView!.reloadData()
        collectionView?.collectionViewLayout.invalidateLayout()
    }
//
//    // I personally added some code in the deinit method as well, in order to cancel the operations when the ViewController is about to get deallocated:
//    deinit {
//        // Cancel all block operations when VC deallocates
//        for operation: NSBlockOperation in blockOperations {
//            operation.cancel()
//        }
//        
//        blockOperations.removeAll(keepCapacity: false)
//    }
}

extension String
{
    func substringFromIndex(index: Int) -> String
    {
        if (index < 0 || index > self.characters.count)
        {
            print("index \(index) out of bounds")
            return ""
        }
        return self.substringFromIndex(self.startIndex.advancedBy(index))
    }
    
    func substringToIndex(index: Int) -> String
    {
        if (index < 0 || index > self.characters.count)
        {
            print("index \(index) out of bounds")
            return ""
        }
        return self.substringToIndex(self.startIndex.advancedBy(index))
    }
    
    func substringWithRange(start: Int, end: Int) -> String
    {
        if (start < 0 || start > self.characters.count)
        {
            print("start index \(start) out of bounds")
            return ""
        }
        else if end < 0 || end > self.characters.count
        {
            print("end index \(end) out of bounds")
            return ""
        }
        let range = Range(start: self.startIndex.advancedBy(start), end: self.startIndex.advancedBy(end))
        return self.substringWithRange(range)
    }
    
    func substringWithRange(start: Int, location: Int) -> String
    {
        if (start < 0 || start > self.characters.count)
        {
            print("start index \(start) out of bounds")
            return ""
        }
        else if location < 0 || start + location > self.characters.count
        {
            print("end index \(start + location) out of bounds")
            return ""
        }
        let range = Range(start: self.startIndex.advancedBy(start), end: self.startIndex.advancedBy(start + location))
        return self.substringWithRange(range)
    }
    
    func curatedString() -> String {
        if self.characters.count == 16 {
            var copy = self.substringFromIndex(12)
            copy = "••••••••••••" + copy
            return copy
        } else {
            return ""
        }
    }
}

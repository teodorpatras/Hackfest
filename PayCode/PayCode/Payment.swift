//
//  Payment.swift
//  PayCode
//
//  Created by Michał Hernas on 26/09/15.
//  Copyright © 2015 Teodor Patras. All rights reserved.
//

import Foundation
import CoreData
import Alamofire



enum PaymentType:String {
    case Paypal = "paypal", Visa = "visa", Mastercard = "mastercard"
    
    func backgroundImage() -> UIImage {
        switch(self) {
        case .Paypal:
            return UIImage(named: "paypal")!
        case .Visa:
            return UIImage(named: "visa")!
        case .Mastercard:
            return UIImage(named: "mastercard")!
        }
    }
    
    func logoImage() -> UIImage {
        switch(self) {
        case .Paypal:
            return UIImage(named: "paypal_logo")!
        case .Visa:
            return UIImage(named: "visa_logo")!
        case .Mastercard:
            return UIImage(named: "mastercard_logo")!
        }
    }
}

class Payment: NSManagedObject {

    var paymentType:PaymentType {
        return PaymentType(rawValue: self.type)!
    }
    
    func deleteFromApi() {
        let request = NSMutableURLRequest(URL: NSURL(string: "http://ohf.hern.as/payments/\(self.id.integerValue)/")!)
        request.HTTPMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        Alamofire.request(request).responseJSON { (request, response, result) -> Void in
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.managedObjectContext.deleteObject(self)
        }
    }
}

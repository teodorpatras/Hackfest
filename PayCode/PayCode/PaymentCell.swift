//
//  PaymentCell.swift
//  PayCode
//
//  Created by Teodor Patras on 26/09/15.
//  Copyright © 2015 Teodor Patras. All rights reserved.
//

import UIKit

class PaymentCell: UICollectionViewCell {

    
    func refresh() {
//        self.paymentView.backgroundColor = self.getRandomColor()
    }
    
    func getRandomColor() -> UIColor{
        
        let randomRed:CGFloat = CGFloat(drand48())
        
        let randomGreen:CGFloat = CGFloat(drand48())
        
        let randomBlue:CGFloat = CGFloat(drand48())
        
        return UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: 1.0)
    }
    
    class func cell() -> PaymentCell
    {
        let cell = NSBundle.mainBundle().loadNibNamed("PaymentCell", owner: nil, options: nil).last as! PaymentCell
        return cell
    }
}

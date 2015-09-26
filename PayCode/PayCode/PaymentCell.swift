//
//  PaymentCell.swift
//  PayCode
//
//  Created by Teodor Patras on 26/09/15.
//  Copyright © 2015 Teodor Patras. All rights reserved.
//

import UIKit

class PaymentCell: UICollectionViewCell {

    @IBOutlet weak var chipView: UIView!
    
    @IBOutlet weak var validLabel: UILabel!
    @IBOutlet weak var identificationLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var logoView: UIImageView!
    @IBOutlet weak var bgView: UIImageView!
    func refresh() {
//        self.paymentView.backgroundColor = self.getRandomColor()
    }
    
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        self.bgView.layer.cornerRadius = 5.0
//        self.bgView.layer.masksToBounds = true
//    }
    
    func configureWithModel(model:Payment) {
        self.bgView.layer.cornerRadius = 5.0
        self.bgView.layer.masksToBounds = true
        self.chipView.layer.cornerRadius = 5.0
        self.chipView.layer.masksToBounds = true
        
        self.bgView.image = model.paymentType.backgroundImage()
        self.logoView.image = model.paymentType.logoImage()
        
        self.nameLabel.text = model.name
        self.validLabel.text = model.validUntill
        self.identificationLabel.text = model.identifier
        
        self.chipView.hidden = model.paymentType == .Paypal
    }
    
    func getRandomColor() -> UIColor{
        
        let randomRed:CGFloat = CGFloat(drand48())
        
        let randomGreen:CGFloat = CGFloat(drand48())
        
        let randomBlue:CGFloat = CGFloat(drand48())
        
        return UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: 1.0)
    }
}

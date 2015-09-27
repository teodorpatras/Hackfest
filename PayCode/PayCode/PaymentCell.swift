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
    
    @IBOutlet weak var dateView: UIView!
    @IBOutlet weak var validLabel: UILabel!
    @IBOutlet weak var identificationLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var logoView: UIImageView!
    @IBOutlet weak var bgView: UIImageView!
    
    var model:Payment!
    override func prepareForReuse() {
        super.prepareForReuse()
        self.model = nil
    }
    
    func configureWithModel(model:Payment) {
        self.model = model
        self.bgView.layer.cornerRadius = 10.0
        self.bgView.layer.masksToBounds = true
        self.chipView.layer.cornerRadius = 5.0
        self.chipView.layer.masksToBounds = true
        
        self.bgView.image = model.paymentType.backgroundImage()
        self.logoView.image = model.paymentType.logoImage()
        
        self.nameLabel.text = model.name
        
        if let validity = model.validUntill {
            self.validLabel.text = validity
            self.dateView.alpha = 1
        } else {
            self.dateView.alpha = 0
        }
        self.identificationLabel.text = model.identifier
        
        self.chipView.hidden = model.paymentType == .Paypal
    }
    
    @IBAction func deleteTapped(sender: AnyObject) {
        
        self.model.deleteFromApi()
    }
    
    func getRandomColor() -> UIColor{
        
        let randomRed:CGFloat = CGFloat(drand48())
        
        let randomGreen:CGFloat = CGFloat(drand48())
        
        let randomBlue:CGFloat = CGFloat(drand48())
        
        return UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: 1.0)
    }
}

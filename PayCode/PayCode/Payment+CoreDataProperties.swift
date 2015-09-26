//
//  Payment+CoreDataProperties.swift
//  PayCode
//
//  Created by Michał Hernas on 26/09/15.
//  Copyright © 2015 Teodor Patras. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Payment {

    @NSManaged var name: String
    @NSManaged var identifier: String
    @NSManaged var validUntill: String?
    @NSManaged var type: String

}

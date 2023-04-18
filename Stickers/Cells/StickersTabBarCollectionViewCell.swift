//
//  StickersTabBarCollectionViewCell.swift
//  MojiEdit
//
//  Created by Ashot Avetyan on 05.03.2021.
//  Copyright © 2021 Ashot Avetyan. All rights reserved.
//

import UIKit

class StickersTabBarCollectionViewCell: UICollectionViewCell {

    static let cellID = "StickersTabBarCollectionViewCell"
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var backgroundTintView: UIView!
    
    var select: Bool = false {
        didSet {
            if select {
                imageView.tintColor = UIColor(named: "6942FFxFFFFFF") ?? .red
                backgroundTintView.backgroundColor = UIColor(named: "E2DAFFx6942FF") ?? .red
            } else {
                imageView.tintColor = UIColor(named: "A5AFB5x5D6368") ?? .red
                backgroundTintView.backgroundColor = UIColor(named: "F8F8F8x222222") ?? .red
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        
        
    }

}

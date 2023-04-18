//
//  StickerCollectionViewCell.swift
//  MojiEdit
//
//  Created by Ashot Avetyan on 05.03.2021.
//  Copyright © 2021 Ashot Avetyan. All rights reserved.
//

import UIKit



extension Notification.Name {
    
    static let didRenderSticker = Notification.Name(rawValue: "didRenderSticker")
    
}


protocol StickerCollectionViewCellDelegate {
    
    func shouldShowPreview(_ stickerName: String)
    
}


class StickerCollectionViewCell: UICollectionViewCell {

    static let cellID = "StickerCollectionViewCell"
    
    @IBOutlet weak var stickerImageView: UIImageView!
    @IBOutlet weak var lockIconImageView: UIImageView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var imageName: String?
    
    var stickerName: String = ""
    
    
    var isLocked: Bool = false {
        didSet {
            lockIconImageView.isHidden = !isLocked
        }
    }
    
    var delegate: StickerCollectionViewCellDelegate?
    
    var longPressGesture: UILongPressGestureRecognizer?
    
    var initialGestureLocation: CGPoint = .zero
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        layer.cornerRadius = 9.0
        
        if #available(iOS 13.0, *) {
            activityIndicator.style = .medium
        }
        
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureAction(_:)))
        longPressGesture?.minimumPressDuration = 0.25
        
        addGestureRecognizer(longPressGesture!)
        
        NotificationCenter.default.addObserver(forName: .didRenderSticker, object: nil, queue: .main) { (notification) in
            if let imageName = notification.userInfo?["imageName"] as? String {
                if imageName == self.imageName {
                    self.stickerImageView.image = StorageProvider.shared.loadImageFromDiskGroupFolder(imageName, isPreview: true)
                    
                    if self.stickerImageView.image != nil {
                        self.activityIndicator.stopAnimating()
                    }
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    @objc
    func longPressGestureAction(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut) {
                self.transform = .init(scaleX: 0.9, y: 0.9)
            } completion: { (finished) in
            }
            
            Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { (_) in
                self.delegate?.shouldShowPreview(self.stickerName)
            }
            
            UIView.animate(withDuration: 0.25, delay: 0.1, options: .curveEaseIn) {
                self.transform = .init(scaleX: 1.1, y: 1.1)
            } completion: { (finished) in
                
            }
        } else if sender.state != .changed {
            layer.removeAllAnimations()
            transform = .identity
        }
        
//        if sender.state == .changed {
//            let location = sender.location(in: self)
//            delegate?.shouldUpdatePreview(position: .init(x: location.x - initialGestureLocation.x, y: location.y - initialGestureLocation.y))
//        }
    }

}

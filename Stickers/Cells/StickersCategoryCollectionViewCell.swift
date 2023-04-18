//
//  StickersCategoryCollectionViewCell.swift
//  MojiEdit
//
//  Created by Ashot Avetyan on 05.03.2021.
//  Copyright © 2021 Ashot Avetyan. All rights reserved.
//

import UIKit


protocol StickersCategoryCollectionViewCellDelegate {
    
    func showStickerDetails(sticker: Sticker)
    
}

class StickersCategoryCollectionViewCell: UICollectionViewCell {

    static let cellID = "StickersCategoryCollectionViewCell"
    
    @IBOutlet var collectionView: UICollectionView!
    
    @IBOutlet var noFavoritesView: UIView!
    
    
    var category = StickerCategory(name: "", path: "", stickers: [])
    var previousCategory: StickerCategory?
    
    var delegate: StickersCategoryCollectionViewCellDelegate?
    
    var moji: Moji?
    
    var collectionViewScale: CGFloat = 1.0 {
        didSet {
            collectionView.transform = CGAffineTransform(scaleX: collectionViewScale, y: collectionViewScale)
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.registerCell(StickerCollectionViewCell.cellID)
        
        collectionView.contentInset = .init(top: 12.0, left: 12.0, bottom: 12.0, right: 12.0)
    }
    
    
    func performTransition(from category: StickerCategory?) {
        previousCategory = nil
        
        guard let category = category else {
            return
        }
        
        var delay = 0.0
        
        for indexPath in collectionView.indexPathsForVisibleItems.sorted() {
            let duration = 0.56 * AppState.current.animationsScaleFactor
            
            let cell = collectionView.cellForItem(at: indexPath) as? StickerCollectionViewCell
            
            cell?.layer.removeAllAnimations()
            
            if category.stickers.count == 0 {
                continue
            }
            
            var sticker = category.stickers[indexPath.item % category.stickers.count]
            
            cell?.stickerName = sticker.path
            
            cell?.isLocked = !PurchaseManager.shared.isSubscribed && sticker.isPaid
            
            if !(cell?.activityIndicator.isAnimating ?? false) {
                cell?.activityIndicator.startAnimating()
            }
            
            cell?.stickerImageView.image = nil
            
            if let imageName = sticker.fullPath(moji: moji) {
                cell?.imageName = imageName
                
                if let savedImage = StorageProvider.shared.loadImageFromDiskGroupFolder(imageName, isPreview: true) {
                    cell?.stickerImageView.image = savedImage
                    cell?.activityIndicator.stopAnimating()
                }
            }
            
            UIView.animate(withDuration: duration / 2.0, delay: delay, options: .curveEaseInOut) {
                cell?.transform = .init(scaleX: 0.01, y: 0.01)
            } completion: { (finished) in
                if finished {
                    cell?.transform = .init(scaleX: 0.01, y: 0.01)
                    
                    sticker = self.category.stickers[indexPath.item]
                    
                    cell?.stickerName = sticker.path
                    
                    cell?.isLocked = !PurchaseManager.shared.isSubscribed && sticker.isPaid
                    
                    if !(cell?.activityIndicator.isAnimating ?? false) {
                        cell?.activityIndicator.startAnimating()
                    }
                    
                    cell?.stickerImageView.image = nil
                    
                    if let imageName = sticker.fullPath(moji: self.moji) {
                        cell?.imageName = imageName
                        
                        if let savedImage = StorageProvider.shared.loadImageFromDiskGroupFolder(imageName, isPreview: true) {
                            cell?.stickerImageView.image = savedImage
                            cell?.activityIndicator.stopAnimating()
                        } else if !sticker.is3D {
                            if let moji = self.moji {
                                Renderer.shared.render(sticker: sticker, in: category, for: moji) { (image) in
                                    if let image = image {
                                        StorageProvider.shared.writeImageToDiskGroupFolder(image, imageName: imageName)
                                        
                                        if let previewImage = image.fitImageIn(128.0) {
                                            let previewPath = imageName.replacingOccurrences(of: ".png", with: "-preview.png")
                                            StorageProvider.shared.writeImageToDiskGroupFolder(previewImage, imageName: previewPath)
                                        }
                                        
                                        NotificationCenter.default.post(name: .didRenderSticker, object: nil, userInfo: [
                                            "imageName": imageName
                                        ])
                                    }
                                }
                            }
                        }
                    }
                    
                    UIView.animate(withDuration: duration / 2.0, delay: 0.0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.0, options: []) {
                        cell?.transform = .identity
                    } completion: { (finished) in
                        
                    }
                }
            }

            delay += 0.05
        }

    }
    
}


extension StickersCategoryCollectionViewCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return category.stickers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfCells: CGFloat = 3.0
        let width = (frame.width - 12.0 * (numberOfCells - 1.0) - collectionView.contentInset.left - collectionView.contentInset.right) / numberOfCells
        
        return .init(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 12.0 * collectionViewScale
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 12.0 * collectionViewScale
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StickerCollectionViewCell.cellID, for: indexPath) as! StickerCollectionViewCell
        
        var sticker: Sticker?
        if category.stickers.count > 0 {
            sticker = category.stickers[indexPath.item]
        }
        cell.stickerName = sticker?.path ?? ""
        
        cell.isLocked = !PurchaseManager.shared.isSubscribed && sticker?.isPaid ?? true
        
        if !cell.activityIndicator.isAnimating {
            cell.activityIndicator.startAnimating()
        }
        
        cell.stickerImageView.image = nil
        
        if let imageName = sticker?.fullPath(moji: moji) {
            cell.imageName = imageName
            
            if let savedImage = StorageProvider.shared.loadImageFromDiskGroupFolder(imageName, isPreview: true) {
                cell.stickerImageView.image = savedImage
                cell.activityIndicator.stopAnimating()
            } else if !(sticker?.is3D ?? true)  {
                if let moji = moji {
                    Renderer.shared.render(sticker: sticker ?? Sticker(name: "", path: "", image: nil, is3D: true, isPaid: true), in: category, for: moji) { (image) in
                        if let image = image {
                            StorageProvider.shared.writeImageToDiskGroupFolder(image, imageName: imageName)
                            
                            if let previewImage = image.fitImageIn(128.0) {
                                let previewPath = imageName.replacingOccurrences(of: ".png", with: "-preview.png")
                                StorageProvider.shared.writeImageToDiskGroupFolder(previewImage, imageName: previewPath)
                            }
                            
                            NotificationCenter.default.post(name: .didRenderSticker, object: nil, userInfo: [
                                "imageName": imageName
                            ])
                        }
                    }
                }
            }
        }
        
        cell.delegate = (delegate as? StickerCollectionViewCellDelegate)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let sticker = category.stickers[indexPath.item]
        delegate?.showStickerDetails(sticker: sticker)
    }
    
}


extension StickersCategoryCollectionViewCell: AnimatedTransitionDelegate {
    
    func playTransitionToAnimation() {
        var delay = 0.25 * AppState.current.animationsScaleFactor
        
        for indexPath in collectionView.indexPathsForVisibleItems.sorted() {
            let cell = collectionView.cellForItem(at: indexPath)
            cell?.transform = .init(scaleX: 0.01, y: 0.01)
            cell?.alpha = 0.0
            
            UIView.animate(withDuration: 0.4 * AppState.current.animationsScaleFactor, delay: delay, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.0, options: []) {
                cell?.transform = .identity
                cell?.alpha = 1.0
            } completion: { _ in
            }

            delay += 0.05 * AppState.current.animationsScaleFactor
        }
    }
    
    func playTransitionFromAnimation() {
        var delay = 0.0
        
        for indexPath in collectionView.indexPathsForVisibleItems.sorted() {
            let cell = collectionView.cellForItem(at: indexPath)
            
            UIView.animate(withDuration: 0.2 * AppState.current.animationsScaleFactor, delay: delay, options: .curveEaseInOut) {
                cell?.transform = .init(scaleX: 0.01, y: 0.01)
                cell?.alpha = 0.0
            } completion: { _ in
            }

            delay += 0.05 * AppState.current.animationsScaleFactor
        }
    }
    
}

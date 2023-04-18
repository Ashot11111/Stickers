//
//  StickersViewController.swift
//  MojiEdit
//
//  Created by Ashot Avetyan on 05.03.2021.
//  Copyright © 2021 Ashot Avetyan. All rights reserved.
//

import UIKit
import SceneKit

struct StickerCategoryContent {
    var name: String
    var iconName: String
}

class StickersViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet var profilePictureImageView: UIImageView!
    @IBOutlet var profilePictureHolderView: UIView!
    @IBOutlet var profilePictureButton: UIButton!
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var categoryTitleLabel: UILabel!
    
    @IBOutlet var separatorView: UIView!
    
    @IBOutlet var tabBarCollectionView: UICollectionView!
    @IBOutlet var categoriesCollectionView: UICollectionView!
    
    @IBOutlet var addMojiView: UIView!
    
    var content: [StickerCategory] = []
    
    var renderView: SCNView?
    var renderFaceNode: ARMoji?
    var finishedRendering3DStickers = true
    var isRendering = false
    var shouldLoad3DAssets = false
    
    var previousCategory: StickerCategory?
    
    var moji: Moji? {
        didSet {
            if moji != nil {
                addMojiView.isHidden = true
                profilePictureButton.setImage(nil, for: .normal)
                
                updateAvatar()
                
                selectedTabBarItem.item = 0
                  
                shouldLoad3DAssets = true
                
                render3DStrickers()
            } else {
                addMojiView.isHidden = false
                profilePictureButton.setImage(UIImage(named: "profilePlaceholder"), for: .normal)
                
                profilePictureHolderView.isHidden = true
                
                selectedTabBarItem.item = -1
            }
        }
    }
    
    let tabBarContent: [StickerCategoryContent] = [
        StickerCategoryContent(name: NSLocalizedString("Featured", comment: "Stickers screen"), iconName: "tabBarFeaturedIcon"),
        StickerCategoryContent(name: NSLocalizedString("Favorites", comment: "Stickers screen"), iconName: "tabBarFavoritesIcon"),
        StickerCategoryContent(name: NSLocalizedString("Greetings", comment: "Stickers screen"), iconName: "tabBarGreetingsIcon"),
        StickerCategoryContent(name: NSLocalizedString("Happy", comment: "Stickers screen"), iconName: "tabBarHappyIcon"),
        StickerCategoryContent(name: NSLocalizedString("Sad", comment: "Stickers screen"), iconName: "tabBarSadIcon"),
        StickerCategoryContent(name: NSLocalizedString("Love", comment: "Stickers screen"), iconName: "tabBarLoveIcon"),
        StickerCategoryContent(name: NSLocalizedString("Celebration", comment: "Stickers screen"), iconName: "tabBarCelebrationIcon"),
    ]
    
    var scrollPositions: [CGPoint] = [
        .zero,
        .zero,
        .zero,
        .zero,
        .zero,
        .zero,
        .zero,
    ]
    
    var selectedTabBarItem = IndexPath(item: 0, section: 0) {
        didSet {
            if oldValue != selectedTabBarItem {
                UIView.transition(with: tabBarCollectionView, duration: 0.25, options: .transitionCrossDissolve) {
                    self.tabBarCollectionView.reloadData()
                } completion: { (_) in
                }
                
                UIView.transition(with: categoryTitleLabel, duration: 0.25, options: .transitionCrossDissolve) {
                    if self.selectedTabBarItem.item >= 0 {
                        self.categoryTitleLabel.text = self.tabBarContent[self.selectedTabBarItem.item].name
                    }
                } completion: { (_) in
                }
                
                Helpers.shared.lightImpactOccured()
            }
        }
    }
    
    var stickerPreviewVC: StickerPreviewViewController?
    
    var shouldPlayTransitionAnimation = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        
        content = StorageProvider.shared.getStickersCategories()
        
        titleLabel.text = NSLocalizedString("Stickers", comment: "Sticker screen title label")
        
        tabBarCollectionView.delegate = self
        tabBarCollectionView.dataSource = self
        
        tabBarCollectionView.registerCell(StickersTabBarCollectionViewCell.cellID)
     
        tabBarCollectionView.contentInset = .init(top: 0.0, left: 13.0, bottom: 0.0, right: 13.0)
        
        if renderView == nil {
            renderView = SCNView(frame: .init(origin: .zero, size: .init(width: 300.0, height: 300.0)))
            renderView?.scene = SCNScene(named: "Models.scnassets/light.scn")!
            renderView?.autoenablesDefaultLighting = true
            renderView?.backgroundColor = .clear
            renderView?.antialiasingMode = .multisampling4X
            
            let camera = SCNCamera()
            camera.fieldOfView = 25.0
            camera.zNear = 0.1
            
            let cameraNode = SCNNode()
            cameraNode.camera = camera
            cameraNode.position.z = 1.0
            
            cameraNode.look(at: .init(x: 0.0, y: 0.00, z: 0.0))
            renderView?.pointOfView = cameraNode
        }
            
        categoriesCollectionView.delegate = self
        categoriesCollectionView.dataSource = self
        
        categoriesCollectionView.registerCell(StickersCategoryCollectionViewCell.cellID)
        
        moji = StorageProvider.shared.moji
        
        NotificationCenter.default.addObserver(forName: .shouldUpdateLibraryView, object: nil, queue: .main) { (notifcation) in
            self.moji = StorageProvider.shared.moji
            self.content = StorageProvider.shared.getStickersCategories()
            self.categoriesCollectionView.reloadData()
        }
        
        NotificationCenter.default.addObserver(forName: .shouldUpdateAvatar, object: nil, queue: .main) { (notification) in
            self.updateAvatar()
        }
        
        profilePictureHolderView.layer.borderWidth = 0.5
        profilePictureHolderView.layer.borderColor = UIColor(white: 0.0, alpha: 0.1).cgColor
        profilePictureHolderView.roundCorners(by: .halfOfWidth)
        
        if !AppState.current.letsGetStartedWasPresented {
            AppState.current.letsGetStartedWasPresented = true
            presentViewController(name: "LetsGetStartedViewController")
        }
        
        if !PurchaseManager.shared.isSubscribed {
            showPurchaseScreen(nil)
        }
        
        showIntroductionMessage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if shouldPlayTransitionAnimation {
            playTransitionToAnimation()
            shouldPlayTransitionAnimation = false
        }
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    func showIntroductionMessage() {
        if AppState.current.stickersIntroductionMessageWasShown {
            return
        }
        
        let introductionMessage = IntroductionMessageView(frame: .init(x: 0, y: 0, width: view.frame.width, height: 147.0))
        introductionMessage.autoresizingMask = [.flexibleWidth]
        
        view.addSubview(introductionMessage)
                
        introductionMessage.frame.origin.y = view.frame.height - introductionMessage.frame.height - (tabBarController?.tabBar.frame.height ?? 0)
        
        introductionMessage.iconImageView.image = UIImage(named: "introductionStickers")
        introductionMessage.descriptionLabel.text = "You can slide between categories to navigate faster."
        
        introductionMessage.closeButton.addAction {
            AppState.current.stickersIntroductionMessageWasShown = true
            introductionMessage.dismiss()
        }
        
        introductionMessage.show()
    }
    
    
    // MARK: - Buttons
 
    @IBAction func addMojiButtonAction(_ sender: Any) {
        presentViewController(name: "GenderSelectionViewController", asPopover: false, addNavigationController: true)
    }
    
    @IBAction func profileButtonAction(_ sender: Any) {
        presentViewController(name: "ChooseMojiViewController", addNavigationController: true) { (controller) in
            let chooseMojiController = controller as? ChooseMojiViewController
            chooseMojiController?.style = .currentMoji
        } completion: { (controller) in
        }
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "StickerSegue" {
            let vc = segue.destination as? StickerDetailsViewController
            
            if let sticker = sender as? Sticker {
                vc?.moji = moji
                vc?.sticker = sticker
            }
        }
    }
    
    
    // MARK: - Other
    
    func updateAvatar() {
        guard let moji = moji else {
            return
        }
        
        let imageName = "\(moji.stickersFolder)/avatar3D.png"
        
        UIView.transition(with: profilePictureImageView, duration: 0.2, options: .transitionCrossDissolve, animations: {
            self.profilePictureImageView.image = StorageProvider.shared.loadImageFromDiskGroupFolder(imageName)
        }, completion: nil)
                        
        profilePictureHolderView.isHidden = false
        
        if moji.backgroundColor <= 0 {
            profilePictureImageView.backgroundColor = UIColor(named: "F8F8F8x2C2C2D")
        } else {
            if traitCollection.userInterfaceStyle == .light {
                profilePictureImageView.backgroundColor = UIColor.mixColor(a: UIColor(rgb: 0xF8F8F8), b: UIColor(rgb: moji.backgroundColor), percentage: 0.15)
            } else {
                profilePictureImageView.backgroundColor = UIColor.mixColor(a: UIColor(rgb: 0x2C2C2D), b: UIColor(rgb: moji.backgroundColor), percentage: 0.15)
            }
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updateAvatar()
    }
        
}


extension StickersViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
        
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tabBarContent.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == tabBarCollectionView {
            return .init(width: 44.0, height: 44.0)
        } else {
            return collectionView.bounds.size
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
        
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == tabBarCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StickersTabBarCollectionViewCell.cellID, for: indexPath) as! StickersTabBarCollectionViewCell
            
            let iconName = tabBarContent[indexPath.item].iconName
            
            if indexPath == selectedTabBarItem {
                cell.imageView.image = UIImage(named: "\(iconName)Selected")
            } else {
                cell.imageView.image = UIImage(named: iconName)
            }
            
            cell.layer.cornerRadius = 22.0
            cell.select = indexPath == selectedTabBarItem
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StickersCategoryCollectionViewCell.cellID, for: indexPath) as! StickersCategoryCollectionViewCell
            
            cell.collectionView.transform = .identity
            cell.collectionView.frame.origin.x = 0.0
            cell.collectionView.alpha = 1.0
            
            cell.category = content[indexPath.item]
            cell.previousCategory = previousCategory?.stickers.count ?? 0 > 0 ? previousCategory : nil
            
            cell.moji = moji
            cell.collectionView.reloadData()
            
            cell.collectionView.contentOffset = scrollPositions[indexPath.item]
            
            if content[indexPath.item].stickers.count == 0 {
                cell.noFavoritesView.isHidden = false
            } else {
                cell.noFavoritesView.isHidden = true
            }
            
            cell.delegate = self
            
            return cell
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == tabBarCollectionView {
            if addMojiView.isHidden {
                previousCategory = content[selectedTabBarItem.item]
                
                categoriesCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
                
                categoriesCollectionView.performBatchUpdates(nil) { _ in
                    for indexPath in self.categoriesCollectionView.indexPathsForVisibleItems {
                        let cell = self.categoriesCollectionView.cellForItem(at: indexPath)
                        (cell as? StickersCategoryCollectionViewCell)?.performTransition(from: self.previousCategory)
                    }
                    
                    self.previousCategory = nil
                }
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == categoriesCollectionView {
            var scrollProgress = categoriesCollectionView.contentOffset.x / categoriesCollectionView.contentSize.width * CGFloat(tabBarContent.count)
            scrollProgress.round()
            
            selectedTabBarItem = IndexPath(item: min(tabBarContent.count - 1, max(0, Int(scrollProgress))), section: 0)
            
            for indexPath in categoriesCollectionView.indexPathsForVisibleItems.sorted() {
                if let cell = categoriesCollectionView.cellForItem(at: indexPath) as? StickersCategoryCollectionViewCell {
                    scrollPositions[indexPath.item] = cell.collectionView.contentOffset
                }
            }
        }
    }
    
}


extension StickersViewController: StickersCategoryCollectionViewCellDelegate {
    
    func showStickerDetails(sticker: Sticker) {
        performSegue(withIdentifier: "StickerSegue", sender: sticker)
    }
    
}


extension StickersViewController {
    
    func render3DStrickers() {

        if isRendering {
            return
        }
        
        if let moji = moji {
            finishedRendering3DStickers = false
            
            let stickers3D = content[0].stickers
            
            for index in 0 ..< stickers3D.count {
                if !stickers3D[index].is3D {
                    continue
                }
                
                let stickerName = stickers3D[index].path
                let imageName = "\(moji.stickersFolder)/\(stickerName).png"
                
                if !StorageProvider.shared.checkImageFromDiskGroupFolder(imageName) {
                    print("node renderSticker")
                    renderSticker(stickerName) { (sticker) in
                        self.categoriesCollectionView.reloadData()
                        
                        if index != stickers3D.count - 1 {
                            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { (timer) in
                               // StorageProvider.shared.deleteStickers(for: moji)
                                self.render3DStrickers()
                            }
                        } else {
                            self.renderFaceNode?.removeFromParentNode()
                            self.shouldLoad3DAssets = true
                            self.finishedRendering3DStickers = true
                            self.categoriesCollectionView.reloadData()
                        }
                        
                        NotificationCenter.default.post(name: .didRenderSticker, object: nil, userInfo: ["imageName": imageName])
                    }
                    
                    return
                }
            }
            
            finishedRendering3DStickers = true
            categoriesCollectionView.reloadData()
        }
    }
      
    func renderSticker(_ stickerName: String, completion: @escaping ((UIImage?) -> Void)) {
        if let moji = moji {
            if !isRendering {
                isRendering = true
                print("node call ")
                if shouldLoad3DAssets {
                    renderFaceNode?.removeFromParentNode()
                    print("node call 1")
                    if stickerName.hasPrefix("new") {
                        print("new node")
                        shouldLoad3DAssets = true
                        renderFaceNode = ARMoji.init(moji: moji.get3DMoji(), headFileName: stickerName)
                    }else {
                        print("old node")
                        renderFaceNode = ARMoji(moji: moji.get3DMoji())
                        shouldLoad3DAssets = false
                    }
                    renderView?.scene?.rootNode.addChildNode(renderFaceNode!)
                    
                    let imageName = "\(moji.stickersFolder)/avatar3D.png"
                    print("imageName == \(stickerName)")
                    if !StorageProvider.shared.checkImageFromDiskGroupFolder(imageName) {
                        renderView?.fitModelInView(renderFaceNode?.childNode(withName: "renderFocus", recursively: true))
                        
                        if let image = renderView?.snapshot() {
                            StorageProvider.shared.writeImageToDiskGroupFolder(image, imageName: imageName)
                        }
                    }
                                        
                    
                }
                print("node call 2")
                DispatchQueue.global(qos: .default).async { [unowned self] in
                    self.renderFaceNode?.stickerNode.isHidden = false
                    self.renderFaceNode?.change(sticker: stickerName)
                    print("node = \(self.renderFaceNode)")
                    self.renderView?.fitModelInView(self.renderFaceNode)
                    
                    DispatchQueue.main.async {
                        if let finalImage = self.renderView?.snapshot() {
                            let imageName = "\(moji.stickersFolder)/\(stickerName).png"
                            if !StorageProvider.shared.checkImageFromDiskGroupFolder(imageName) {
                                if let previewImage = finalImage.fitImageIn(200.0) {
                                    let previewFileName = imageName.replacingOccurrences(of: ".png", with: "-preview.png")
                                    StorageProvider.shared.writeImageToDiskGroupFolder(previewImage, imageName: previewFileName)
                                }
                            print("node name  = \(imageName)")
                            if !StorageProvider.shared.checkImageFromDiskGroupFolder(imageName) {
                                print("node save")
                                  StorageProvider.shared.writeImageToDiskGroupFolder(finalImage, imageName: imageName)
                                }
                            }
                            self.isRendering = false
                            
                            completion(finalImage)
                        } else {
                            self.isRendering = false
                            
                            completion(nil)
                        }
                    }
                }
            } else {
                isRendering = false
                completion(nil)
            }
        } else {
            isRendering = false
            completion(nil)
        }
    }
    
}


extension StickersViewController: StickerCollectionViewCellDelegate {
            
    func shouldShowPreview(_ stickerName: String) {
        if let vc = storyboard?.instantiateViewController(withIdentifier: "StickerPreviewViewController") as? StickerPreviewViewController {
            Helpers.shared.lightImpactOccured()
                    
            stickerPreviewVC = vc
            
            vc.moji = moji
            vc.sticker = StorageProvider.shared.getSticker(named: stickerName)
            
            tabBarController?.present(vc, animated: false, completion: {
                vc.show()
            })
        }
    }
}


extension StickersViewController: AnimatedTransitionDelegate {
    
    func playTransitionToAnimation() {
        if titleLabel == nil {
            shouldPlayTransitionAnimation = true
            return
        }
                
        titleLabel.alpha = 0.0
        titleLabel.transform = .init(translationX: 0.0, y: 50.0)
        
        categoryTitleLabel.alpha = 0.0
        categoryTitleLabel.transform = .init(translationX: 0.0, y: 50.0)
        
        separatorView.alpha = 0.0
        separatorView.transform = .init(translationX: 0.0, y: 50.0)
        
        profilePictureHolderView.transform = .init(scaleX: 0.01, y: 0.01)
        
        UIView.animate(withDuration: 0.4 * AppState.current.animationsScaleFactor, delay: 0.25 * AppState.current.animationsScaleFactor, options: .curveEaseInOut) { [self] in
            
            titleLabel.alpha = 1.0
            titleLabel.transform = .identity
            
            categoryTitleLabel.alpha = 1.0
            categoryTitleLabel.transform = .identity
            
            separatorView.alpha = 1.0
            separatorView.transform = .identity
            
            profilePictureHolderView.transform = .identity
        } completion: { _ in
        }
        
        var delay = 0.3 * AppState.current.animationsScaleFactor
        
        for item in 0 ..< tabBarCollectionView.numberOfItems(inSection: 0) {
            let cell = tabBarCollectionView.cellForItem(at: .init(item: item, section: 0))
            cell?.transform = .init(scaleX: 0.01, y: 0.01)
            cell?.alpha = 0.0
            
            UIView.animate(withDuration: 0.2 * AppState.current.animationsScaleFactor, delay: delay, options: .curveEaseInOut) {
                cell?.transform = .identity
                cell?.alpha = 1.0
            } completion: { _ in
            }

            delay += 0.05 * AppState.current.animationsScaleFactor
        }
        
        for indexPath in categoriesCollectionView.indexPathsForVisibleItems {
            let cell = categoriesCollectionView.cellForItem(at: indexPath)
            
            (cell as? AnimatedTransitionDelegate)?.playTransitionToAnimation()
        }
        
    }
    
    func playTransitionFromAnimation() {
        var delay = 0.0
        
        for item in 0 ..< tabBarCollectionView.numberOfItems(inSection: 0) {
            let cell = tabBarCollectionView.cellForItem(at: .init(item: item, section: 0))
            
            UIView.animate(withDuration: 0.2 * AppState.current.animationsScaleFactor, delay: delay, options: .curveEaseInOut) {
                cell?.transform = .init(scaleX: 0.01, y: 0.01)
                cell?.alpha = 0.0
            } completion: { _ in
                cell?.transform = .identity
            }

            delay += 0.05 * AppState.current.animationsScaleFactor
        }
        
        for indexPath in categoriesCollectionView.indexPathsForVisibleItems {
            let cell = categoriesCollectionView.cellForItem(at: indexPath)
            
            (cell as? AnimatedTransitionDelegate)?.playTransitionFromAnimation()
        }
                
        UIView.animate(withDuration: 0.4 * AppState.current.animationsScaleFactor, delay: 0.0, options: .curveEaseInOut) { [self] in
            
            titleLabel.alpha = 0.0
            titleLabel.transform = .init(translationX: 0.0, y: 50.0)
            
            categoryTitleLabel.alpha = 0.0
            categoryTitleLabel.transform = .init(translationX: 0.0, y: 50.0)
            
            separatorView.alpha = 0.0
            separatorView.transform = .init(translationX: 0.0, y: 50.0)
            
            profilePictureHolderView.transform = .init(scaleX: 0.01, y: 0.01)
        } completion: { _ in
        }
        
    }
    
}

//
//  PhotoDetailViewController.swift
//  WaselDelivery
//
//  Created by Purpletalk on 10/13/17.
//  Copyright © 2017 [x]cube Labs. All rights reserved.
//

import UIKit

class PhotoDetailViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var imageBgView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var productNameLabel: UILabel!
    @IBOutlet weak var descriptionHeaderLabel: UILabel!
    @IBOutlet weak var productNameLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var closeButtonTopConstraint: NSLayoutConstraint!
    var outletItem: OutletItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        
        let doubleTapGest = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapScrollView(recognizer:)))
        doubleTapGest.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapGest)
        
        imageBgView.layer.cornerRadius = 10.0
        imageBgView.layer.masksToBounds = false
        imageBgView.layer.shadowColor = UIColor.gray.cgColor
        imageBgView.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        imageBgView.layer.shadowOpacity = 0.5
        imageBgView.backgroundColor = UIColor.white
        
        if let aOutletItem = outletItem {
            productNameLabel.text = aOutletItem.name ?? ""
            if let itemDescription_ = aOutletItem.itemDescription, false == itemDescription_.isEmpty {
                descriptionTextView.isHidden = false
                descriptionHeaderLabel.isHidden = false
                descriptionTextView.text = itemDescription_
            } else {
                descriptionTextView.isHidden = true
                descriptionHeaderLabel.isHidden = true
                descriptionTextView.text = ""
            }
            let imageUrl_ = aOutletItem.imageUrl ?? ""
            if true == imageUrl_.isEmpty {
                imageView.image = UIImage(named: "profile_placeholder")
            } else {
                UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseIn, animations: {
                    self.imageView.sd_setImage(with: URL(string: imageUrl_), placeholderImage: UIImage(named: "profile_placeholder"))
                }, completion: nil)
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let shadowSize: CGFloat = 5.0
        let shadowPath = UIBezierPath(rect: CGRect(x: -shadowSize / 2, y: -shadowSize / 2, width: imageBgView.frame.size.width + shadowSize, height: imageBgView.frame.size.height + shadowSize))
        imageBgView.layer.shadowPath = shadowPath.cgPath
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        productNameLabelTopConstraint.constant = (true == Utilities.shared.isIphoneX()) ? 49.0 : 25.0
        closeButtonTopConstraint.constant = (true == Utilities.shared.isIphoneX()) ? 49.0 : 25.0
        UIApplication.shared.setStatusBarHidden(true, with: .none)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.setStatusBarHidden(false, with: .none)
    }
    
    @objc func handleDoubleTapScrollView(recognizer: UITapGestureRecognizer) {
        if scrollView.zoomScale == 1 {
            scrollView.zoom(to: zoomRectForScale(scale: scrollView.maximumZoomScale, center: recognizer.location(in: recognizer.view)), animated: true)
        } else {
            scrollView.setZoomScale(1, animated: true)
        }
    }
    
    func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = imageView.frame.size.height / scale
        zoomRect.size.width  = imageView.frame.size.width  / scale
        let newCenter = imageView.convert(center, from: scrollView)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
// MARK: - IBActions
    
    @IBAction func cancelButtonAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}

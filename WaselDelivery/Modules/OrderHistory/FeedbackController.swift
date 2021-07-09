//
//  FeedbackController.swift
//  WaselDelivery
//
//  Created by sunanda on 12/28/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import RxSwift

struct Feedback {
    
    var id: Int?
    var serviceRating: Int = 0
    var orderRating: Int = 0
    var comments = ""
}

class FeedbackController: BaseViewController, UITextViewDelegate {

    @IBOutlet var textViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var commentView: UIView!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet var serviceButtonCollection: [UIButton]!
    @IBOutlet var serviceLabelCollection: [UILabel]!
    
    @IBOutlet weak var starRatingView: UIView!
    
    @IBOutlet weak var outletFeedbackLabel: UILabel!
    @IBOutlet var outletFBImageCollection: [UIImageView]!
    
    @IBOutlet weak var placeholderLabel: UILabel!
    @IBOutlet weak var commentTextView: UITextView!
    
    @IBOutlet weak var viewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var viewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var toolBar: UIToolbar!
    var order: Order?
    private var feedback = Feedback()
    private var disposableBag = DisposeBag()
    
    var pageIndex: Int = 0
    weak var delegate: PageViewProtocol?
    weak var reloadDelegate: ReloadPageController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        feedback.id = order?.id ?? 0
        commentTextView.inputAccessoryView = toolBar
        var commentText = ""
        if order?.orderType == .normal {
            if let aOutlet_ = order?.outlet {
                let outletName = aOutlet_.name ?? "" // Utilities.fetchOutletName(aOutlet_)
                commentText.append("Please rate product from \(outletName)")
            }
        } else {
            if let location_ = order?.pickUpLocation {
                commentText.append("Please rate product picked from \(location_)")
            }
        }
        outletFeedbackLabel.text = commentText
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardDidShow(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        Utilities.removeTransparentView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        Utilities.showTransparentView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UPSHOTActivitySetup.shared.createPageViewEvent(currentPage: BKConstants.FEEDBACK_SCREEN)
        if let delegate_ = delegate {
            delegate_.updateCurrentIndex(pageIndex)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
// MARK: - Notification Methods
    
    @objc private func keyboardDidShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo else {
            return
        }
        guard let keyboardHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height else {
            return
        }
        var contentInset: UIEdgeInsets = self.scrollView.contentInset
        contentInset.bottom = keyboardHeight + TabBarHeight
        self.scrollView.contentInset = contentInset
        self.commentTextView.becomeFirstResponder()
        let frame = self.view.convert(self.commentView.frame, from: self.bottomView)
        self.scrollView.scrollRectToVisible(frame, animated: true)
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        let contentInset: UIEdgeInsets = UIEdgeInsets.zero
        self.scrollView.contentInset = contentInset
    }
    
// MARK: - IBActions
    
    @IBAction func submitAction(_ sender: Any) {
        
        guard feedback.serviceRating != 0 && feedback.orderRating != 0 else {
            Utilities.showToastWithMessage("Please rate your experience.")
            return
        }
        
        guard feedback.serviceRating != 0 else {
            Utilities.showToastWithMessage("Please rate the delivery.")
            return
        }
        
        guard feedback.orderRating != 0 else {
            Utilities.showToastWithMessage("Please rate the product.")
            return
        }
        
        let feedBackId = feedback.id ?? 0
        let feedbackObj: [[String: AnyObject]] = [[OrderIdKey: feedBackId as AnyObject,
                                                   RatingKey: feedback.orderRating as AnyObject,
                                                   DeliveryRatingKey: feedback.serviceRating as AnyObject,
                                                   CommentsKey: feedback.comments as AnyObject]]
        
        giveFeedback(feedbackObj)        
    }
    
    @IBAction func giveServiceFeedback(_ sender: UIButton) {
        
        for button in serviceButtonCollection {
            if button == sender {
                button.isSelected = !button.isSelected
                feedback.serviceRating = (button.isSelected == true) ? sender.tag : 0
            } else {
                button.isSelected = false
            }
        }
        
        for label in serviceLabelCollection {
            if sender.tag == label.tag && sender.isSelected == true {
                label.textColor = UIColor(red: (255.0/255.0), green: (236.0/255.0), blue: (51.0/255.0), alpha: 1.0)
            } else {
                label.textColor = .white
            }
        }
        
    }
    
    @IBAction func doneEditing(_ sender: Any) {
        view.endEditing(true)
    }
    
    @IBAction func giveStarRating(_ sender: UIGestureRecognizer) {
        
        let locationX = sender.location(in: starRatingView).x
        var tag = -1
        for imageView in outletFBImageCollection.reversed() {
            
            if locationX > imageView.frame.minX {
                tag = imageView.tag
                feedback.orderRating = tag
                break
            } else {
                feedback.orderRating = 0
            }
        }

        for imageView in outletFBImageCollection.reversed() {
            if imageView.tag <= tag && tag != -1 {
                imageView.image = UIImage(named: "starOn")
            } else {
                imageView.image = UIImage(named: "starOff")
            }
        }
    }
    
// MARK: - SupportMethods

    private func giveFeedback(_ reqObj: [[String: AnyObject]]) {
        
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }
        
        Utilities.showHUD(to: self.view, nil)
        ApiManager.shared.apiService.giveFeedback(reqObj)
            .subscribe(onNext: { [weak self](_) in
                Utilities.hideHUD(from: self?.view)
                if let reloadDelegate_ = self?.reloadDelegate, let index_ = self?.pageIndex {
                    reloadDelegate_.reloadPageController(orderIndex: index_)
                }
            }, onError: { [weak self](error) in
                Utilities.hideHUD(from: self?.view)
                if let error_ = error as? ResponseError {
                    if error_.getStatusCodeFromError() == .accessTokenExpire {
                        
                    } else {
                        Utilities.showToastWithMessage(error_.description())
                    }
                } else {
                    Utilities.showToastWithMessage(error.localizedDescription)
                }
            }).disposed(by: disposableBag)
    }
// MARK: - UITextViewDelegate
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        let currentCharacterCount = textView.text?.count ?? 0
        if range.length + range.location > currentCharacterCount {
            return false
        }
        
        let newLength = currentCharacterCount + text.count - range.length
        return newLength <= 240
    }

    func textViewDidChange(_ textView: UITextView) {
        
        let textLength = textView.text.count
        placeholderLabel.isHidden = textLength > 0 ? true : false
        
        let fixedWidth = textView.frame.size.width
        textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        var newFrame = textView.frame
        newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
        
        let maxY = commentView.frame.minY + newFrame.height
        let limit = submitButton.frame.minY - 20.0
        
        if maxY > limit {
            textView.frame = textView.frame
            textView.isScrollEnabled = true
            textViewHeightConstraint.isActive = true
            textViewHeightConstraint.constant = textView.frame.height
        } else {
            textView.isScrollEnabled = false
            textView.frame = newFrame
            textViewHeightConstraint.isActive = false
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        feedback.comments = textView.text?.trim() ?? ""
    }

}

protocol ReloadPageController: class {
    func reloadPageController(orderIndex: Int)
}

//
//  OrderCancelCommentsCell.swift
//  WaselDelivery
//
//  Created by Purpletalk on 03/01/18.
//  Copyright © 2018 [x]cube Labs. All rights reserved.
//

import UIKit

class OrderCancelCommentsCell: UITableViewCell, UITextViewDelegate {
    
    @IBOutlet weak var commentsTextView: UITextView!
    @IBOutlet weak var placeHolderLabel: UILabel!
    weak var delegate: OrderCancelCommentsCellProtocol?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.isExclusiveTouch = true
    }
    
    class func nib() -> UINib {
        return UINib(nibName: "OrderCancelCommentsCell", bundle: nil)
    }

    class func cellIdentifier() -> String {
        return "OrderCancelCommentsCell"
    }

// MARK: - User defined methods

    func loadCommentsData(commentText: String) {
        commentsTextView.text = commentText
        placeHolderLabel.isHidden = (commentText.count > 0) ? true : false
    }
    
// MARK: - TextView delegate methods

    func textViewDidChange(_ textView: UITextView) {
        
        let textLength = textView.text.count
        placeHolderLabel.isHidden = textLength > 0 ? true : false
        delegate?.textViewDidChangeCharacters(textView)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if false == text.canBeConverted(to: .ascii) {
            return false
        }
        
        let currentCharacterCount = textView.text?.count ?? 0
        if range.length + range.location > currentCharacterCount {
            return false
        }
        
        let newLength = currentCharacterCount + text.count - range.length
        return newLength <= 240
    }
    
}

protocol OrderCancelCommentsCellProtocol: class {
    func textViewDidChangeCharacters(_ textView: UITextView)
}

//
//  SearchHistoryCell.swift
//  WaselDelivery
//
//  Created by Karthik on 28/11/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

protocol SearchHistoryCellDelegate: class {
    func searchHistoryCell(cell: SearchHistoryCell, didSelectClearHistory historyItem: String)
    func reloadSearch(cell: SearchHistoryCell, didSelectClearHistory historyItem: String)
}

class SearchHistoryCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var clearButton: UIButton!
    
    @IBOutlet weak var historyItemButton: UIButton?
    @IBOutlet weak var ellipsisImage: UIImageView!
    weak var delegate: SearchHistoryCellDelegate?
    
    func configureCell(with historyItem: String) {
        clearButton.isHidden = false
        historyItemButton?.isHidden = false

        nameLabel.text = historyItem
    }
    
    func showMore() {
        ellipsisImage.isHidden = false
        clearButton.isHidden = true
        historyItemButton?.isHidden = true

        nameLabel.text = "MORE FROM RECENT HISTORY"
        nameLabel.textColor = UIColor(red: 152.0/255.0, green: 152.0/255.0, blue: 152.0/255.0, alpha: 1.0)
    }
    
    @IBAction func clearButtonClicked(_ sender: UIButton) {
        delegate?.searchHistoryCell(cell: self, didSelectClearHistory: "")
    }
    
    @IBAction func historyButtonClicked(_ sender: UIButton) {
        delegate?.reloadSearch(cell: self, didSelectClearHistory: self.nameLabel.text ?? "")
    }
    
    class func cellIdentifier() -> String {
        return "SearchHistoryCell"
    }
}

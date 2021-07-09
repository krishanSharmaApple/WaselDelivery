//
//  CustomizeItemController.swift
//  WaselDelivery
//
//  Created by sunanda on 11/25/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

class CustomizeItemController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    var pageIndex: NSInteger = 0
    var currentRow: Int = 0
    var category: CustomizeCategory?
    weak var delegate: PageViewProtocol?

    @IBOutlet weak var customizeTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        customizeTableView.estimatedRowHeight = 82.0
        customizeTableView.rowHeight = UITableView.automaticDimension
        if category?.categoryMode == .anyOne {
            if let categoryItems_ = category?.items {
                for (index, item) in categoryItems_.enumerated() where item.isRadioSelectionEnabled == true {
                    currentRow = index
                    break
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if category != nil {
            customizeTableView.reloadData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let delegate_ = delegate {
            delegate_.updateCurrentIndex(pageIndex)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
// MARK: - UITableViewDelegate and Datasource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let category_ = category, let items_ = category_.items {
            return items_.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CustomizeCell.cellIdentifier(), for: indexPath) as? CustomizeCell else {
            return UITableViewCell()
        }
        if let categoryItems_ = category?.items, let categoryMode_ = category?.categoryMode {
            cell.loadCellWith(item: categoryItems_[indexPath.row], withCategoryMode: categoryMode_)
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let category_ = category, let items_ = category_.items {
            
            if category_.categoryMode == .check {
                let item_ = items_[indexPath.row]
                item_.isCheck = !item_.isCheck
                let cell = tableView.cellForRow(at: indexPath) as? CustomizeCell
                cell?.updateCustomizeItemCartUI()
                var count = Utilities.shared.customItemsCount
                count = (item_.isCheck == true) ? count + 1 : (count > 0) ? count - 1 : 0
                Utilities.shared.customItemsCount = count
            } else if category_.categoryMode == .anyOne {
                if currentRow != indexPath.row {
                    let prevItem_ = items_[currentRow]
                    prevItem_.isRadioSelectionEnabled = false
                    let currentItem_ = items_[indexPath.row]
                    currentItem_.isRadioSelectionEnabled = true
                    currentRow = indexPath.row
                }
                customizeTableView.reloadData()
            }
        }
    }
    
}

class CustomizeCell: UITableViewCell {
    
    @IBOutlet weak var anyOneTitleLabel: UILabel!
    @IBOutlet weak var quantityTitleLabel: UILabel!
    @IBOutlet weak var multipleTitleLabel: UILabel!
    
    @IBOutlet weak var anyOneBDImageView: UIImageView!
    @IBOutlet weak var quantityBDImageView: UIImageView!
    @IBOutlet weak var multipleBDImageView: UIImageView!
    
    @IBOutlet weak var decButton: UIButton!
    @IBOutlet weak var incrementButton: UIButton!
    @IBOutlet weak var decrementButton: UIButton!
    @IBOutlet weak var quantityCountLabel: UILabel!
    
    @IBOutlet weak var quantityView: UIView!
    @IBOutlet weak var anyOneView: UIView!
    @IBOutlet weak var multipleView: UIView!
    
    @IBOutlet var multipleButton: UIButton!
    
    @IBOutlet weak var multiplePriceView: UIView!
    @IBOutlet weak var multiplePriceLabel: UILabel!
    
    @IBOutlet weak var quantityPriceView: UIView!
    @IBOutlet weak var quantityPriceLabel: UILabel!
    
    @IBOutlet weak var anyonePriceView: UIView!
    @IBOutlet weak var anyonePriceLabel: UILabel!
    
    @IBOutlet weak var anyOneImageView: UIImageView!
    
    @IBOutlet weak var quantityPriceWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var multiplePriceWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var anyonePriceWidthConstraint: NSLayoutConstraint!

    var customizeItem: CustomizeItem?
    var categoryMode: CategoryMode?
    var attTitle: NSMutableAttributedString?
    
    class func cellIdentifier() -> String {
        return "CustomizeCell"
    }

    func loadCellWith(item: CustomizeItem, withCategoryMode mode: CategoryMode) {
        customizeItem = item
        categoryMode = mode
        self.contentView.layoutIfNeeded()
        updateCustomizeItemCartUI()
    }
    
// MARK: - IBActions
    
    @IBAction func incrementAction(_ sender: Any) {
        
        guard Utilities.shared.customItemsCount < 99 else {
            Utilities.showToastWithMessage("CustomItems limited to 99.")
            return
        }
        
        if let customizeItem_ = customizeItem {
            customizeItem_.quantity += 1
            Utilities.shared.customItemsCount += 1
        }
        updateCustomizeItemCartUI()
    }
    
    @IBAction func decrementAction(_ sender: Any) {
        if let customizeItem_ = customizeItem {
            customizeItem_.quantity -= 1
            if Utilities.shared.customItemsCount > 0 {
                Utilities.shared.customItemsCount -= 1
            }
        }
        updateCustomizeItemCartUI()
    }
    
    // MARK: - Update UI
    
    func updateCustomizeItemCartUI() {
        
        if let categoryMode_ = categoryMode {
            multipleView.isHidden = true
            anyOneView.isHidden = true
            quantityView.isHidden = true
            switch categoryMode_ {
            case .count: updateCountView()
            case .check: updateCheckView()
            case .anyOne: updateAnyoneView()
            }
            NotificationCenter.default.post(name: Notification.Name(rawValue: UpdateCustomizationNotification), object: nil, userInfo: nil)
        }
    }
    
    private func updateCountView() {
        
        if let customizeItem_ = customizeItem {
            quantityTitleLabel.text = customizeItem_.name ?? ""
            quantityView.isHidden = false
            incrementButton.layer.borderColor = UIColor.black.cgColor
            decrementButton.layer.borderColor = (customizeItem_.quantity > 0) ? UIColor.black.cgColor : UIColor.lightGray.cgColor
            decButton.isEnabled = (customizeItem_.quantity > 0) ? true : false
            decrementButton.isEnabled = (customizeItem_.quantity > 0) ? true : false
            quantityCountLabel.text = "\(customizeItem_.quantity)"
            quantityPriceView.isHidden = false
            if let price_ = customizeItem_.price, price_ > 0 {
                quantityBDImageView.isHidden = false
//                quantityPriceView.isHidden = false
                let priceText_ = String(format: "%.3f", price_)
                let width_ = Utilities.getSizeForText(text: priceText_, font: UIFont.montserratLightWithSize(16.0), fixedHeight: 41.0).width
                quantityPriceWidthConstraint.constant = width_
                quantityPriceLabel.text = priceText_
            } else {
                multiplePriceWidthConstraint.constant = 0.0
//                quantityPriceView.isHidden = true
                let priceText_ = NSLocalizedString("FREE", comment: "")
                let width_ = Utilities.getSizeForText(text: priceText_, font: UIFont.montserratLightWithSize(16.0), fixedHeight: 41.0).width
                quantityPriceWidthConstraint.constant = width_
                quantityPriceLabel.text = priceText_
                quantityBDImageView.isHidden = true
            }
            contentView.layoutIfNeeded()
        }
    }
    
    private func updateCheckView() {
        if let customizeItem_ = customizeItem {
            anyOneTitleLabel.text = customizeItem_.name ?? ""
            anyOneView.isHidden = false
            anyOneImageView.isHidden = !customizeItem_.isCheck
            customizeItem?.quantity = (customizeItem_.isCheck == true) ? 1 : 0
            anyonePriceView.isHidden = false
            if let price_ = customizeItem_.price, price_ > 0 {
                anyOneBDImageView.isHidden = false
//                anyonePriceView.isHidden = false
                let priceText_ = String(format: "%.3f", price_)
                let width_ = Utilities.getSizeForText(text: priceText_, font: UIFont.montserratLightWithSize(16.0), fixedHeight: 41.0).width
                anyonePriceWidthConstraint.constant = width_
                anyonePriceLabel.text = priceText_
            } else {
                multiplePriceWidthConstraint.constant = 0.0
//                anyonePriceView.isHidden = true
                let priceText_ = NSLocalizedString("FREE", comment: "")
                let width_ = Utilities.getSizeForText(text: priceText_, font: UIFont.montserratLightWithSize(16.0), fixedHeight: 41.0).width
                anyonePriceWidthConstraint.constant = width_
                anyonePriceLabel.text = priceText_
                anyOneBDImageView.isHidden = true
            }
            contentView.layoutIfNeeded()
        }
    }
    
    private func updateAnyoneView() {
        if let customizeItem_ = customizeItem {
            multipleTitleLabel.text = customizeItem_.name ?? ""
            multipleView.isHidden = false
            multipleButton.isSelected = customizeItem_.isRadioSelectionEnabled
            customizeItem?.quantity = (multipleButton.isSelected == true) ? 1 : 0
            multiplePriceView.isHidden = false
            if let price_ = customizeItem_.price, price_ > 0 {
                multipleBDImageView.isHidden = false
//                multiplePriceView.isHidden = false
                let priceText_ = String(format: "%.3f", price_)
                let width_ = Utilities.getSizeForText(text: priceText_, font: UIFont.montserratLightWithSize(16.0), fixedHeight: 41.0).width
                multiplePriceWidthConstraint.constant = width_
                multiplePriceLabel.text = priceText_
            } else {
                multiplePriceWidthConstraint.constant = 0.0
//                multiplePriceView.isHidden = true
                
                let priceText_ = NSLocalizedString("FREE", comment: "")
                let width_ = Utilities.getSizeForText(text: priceText_, font: UIFont.montserratLightWithSize(16.0), fixedHeight: 41.0).width
                multiplePriceWidthConstraint.constant = width_
                multiplePriceLabel.text = priceText_
                multipleBDImageView.isHidden = true
            }
            contentView.layoutIfNeeded()
        }
    }

}

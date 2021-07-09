//
//  SearchCategoryCell.swift
//  WaselDelivery
//
//  Created by Karthik on 28/11/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

protocol SearchCategoryCellDelegate: class {
    func searchCategoryCell(cell: SearchCategoryCell, didSelect index: Int)
}

class SearchCategoryCell: UITableViewCell {
    
    @IBOutlet weak var collectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var categoryCollectionView: UICollectionView!
    weak var delegate: SearchCategoryCellDelegate?
    
    var categoriesArray: [Amenity]?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.categoryCollectionView.register(CategoryCollectionViewCell.nib(), forCellWithReuseIdentifier: CategoryCollectionViewCell.cellIdentifier())
    }
    
    class func cellIdentifier() -> String {
        return "SearchCategoryCell"
    }
    
    class func nib() -> UINib {
        return UINib(nibName: "SearchCategoryCell", bundle: nil)
    }
    
}

extension SearchCategoryCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let categoriesArray_ = Utilities.shared.amenities, categoriesArray_.count > 0 {
            return categoriesArray_.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryCollectionViewCell.cellIdentifier(), for: indexPath) as? CategoryCollectionViewCell else {
            return UICollectionViewCell()
        }
        guard let amenities_ = Utilities.shared.amenities else {
            return UICollectionViewCell()
        }
        if indexPath.row < amenities_.count {
            let amenity = amenities_[indexPath.row]
            let isFirstRow = (3 > indexPath.row) ? true : false
            let isFirstColumn = (0 == indexPath.row % 3) ? true : false
            cell.configureCell(amenity, isFirstRow: isFirstRow, isFirstColumn: isFirstColumn)
            return cell
        }
        cell.configureCell(nil)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let cellFrame = ((collectionView.bounds.size.width - 4.0)/3.0)
        return CGSize(width: cellFrame, height: cellFrame)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let amenities_ = Utilities.shared.amenities {
            if indexPath.row <= amenities_.count - 1 {
                delegate?.searchCategoryCell(cell: self, didSelect: indexPath.row)
            }
        }
    }
    
    func getCollectionViewContentSize() -> CGSize {
        return self.categoryCollectionView.contentSize
    }
    
    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        categoryCollectionView.frame = CGRect(x: 0, y: 0, width: targetSize.width, height: CGFloat(MAXFLOAT))
        categoryCollectionView.layoutIfNeeded()
        return categoryCollectionView.collectionViewLayout.collectionViewContentSize
    }
    
}

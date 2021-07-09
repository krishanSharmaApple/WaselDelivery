//
//  HomeHeader.swift
//  WeselDeliverySample
//
//  Created by sunanda on 9/16/16.
//  Copyright © 2016 purpletalk. All rights reserved.
//

import UIKit

private func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

private func > <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

class HomeHeader: UIView {

    @IBOutlet weak var departmentCollectionView: UICollectionView!
    var distributeEqually = false
    
    var titles: [Amenity]? {
        didSet {
            if nil == titles {
                return
            }
            let totalWidth = getTotalWidth()
            distributeEqually = (totalWidth < ScreenWidth) ? true : false
            departmentCollectionView.reloadData()
        }
    }
    
    var titleWidths: [CGFloat]!
    var selectedIndexPath: IndexPath?
    weak var delegate: HeaderProtocol?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) { 
        super.init(coder: aDecoder)
        self.xibSetup()
    }
    
    fileprivate func xibSetup() {
        let view: UIView = loadViewFromNib()
        view.frame = bounds
        addSubview(view)
        selectedIndexPath = IndexPath(item: 0, section: 0)
        departmentCollectionView.dataSource = self
        departmentCollectionView.delegate = self
        departmentCollectionView.register(DepartmentCell.nib(), forCellWithReuseIdentifier: DepartmentCell.cellIdentifier())
    }
    
    fileprivate func loadViewFromNib() -> UIView {
        let nib = UINib(nibName: "HomeHeader", bundle: nil)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as? UIView ?? UIView()
        return view
    }

    func updateSelectedDepartment(_ index: Int) {
        
        if titles?.count > 0 {
            selectedIndexPath = IndexPath(item: index, section: 0)
            departmentCollectionView.reloadData()
            if let selectedIndexPath_ = selectedIndexPath {
                departmentCollectionView.scrollToItem(at: selectedIndexPath_, at: .centeredHorizontally, animated: true)
            }
        }
    }
    
    fileprivate func getTotalWidth() -> CGFloat {
        
        if let aTitles_ = titles {
            titleWidths = aTitles_.map { (amenity) -> CGFloat in
                if let name_ = amenity.name {
                    return Utilities.getSizeForText(text: name_, font: UIFont.montserratRegularWithSize(14.0), fixedHeight: 69.0).width + 10.0
                }
                return 0.0
                }.compactMap { $0 }
        }
        return  titleWidths.reduce (0.0) { acc, titleWidth in return acc + (titleWidth + 20.0) } //including minItemSpacing
    }
    
    deinit {
        Utilities.log("HomeHeader deinit" as AnyObject, type: .trace)
    }
}

extension HomeHeader: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let titlesCount = titles?.count, 0 < titlesCount {
            return titlesCount
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DepartmentCell.cellIdentifier(), for: indexPath) as? DepartmentCell else {
            return UICollectionViewCell()
        }
        cell.isSelected = selectedIndexPath == indexPath ? true : false
        if let amenity = titles?[indexPath.row] {
            cell.loadCellTitle(identity: amenity)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if distributeEqually == true {
            var width: CGFloat = 0.0
            if let titlesCount = titles?.count, 0 < titlesCount {
                width = ScreenWidth / CGFloat(titlesCount)
            }
            return CGSize(width: width, height: 69.0)
        }
        return CGSize(width: titleWidths[indexPath.item], height: 69.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if distributeEqually == true {
            return 0.0
        }
        return 20.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if distributeEqually == true {
            return UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        }
        return UIEdgeInsets(top: 0.0, left: 20.0, bottom: 0.0, right: 20.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if selectedIndexPath != indexPath {
            selectedIndexPath = indexPath
            departmentCollectionView.reloadData()
            if let selectedIndexPath_ = selectedIndexPath {
                departmentCollectionView.scrollToItem(at: selectedIndexPath_, at: .centeredHorizontally, animated: true)
                delegate?.scrollToViewController(selectedIndexPath_.item)
            }
        }
    }
}

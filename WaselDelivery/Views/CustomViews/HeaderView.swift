//
//  HeaderView.swift
//  WeselDeliverySample
//
//  Created by sunanda on 9/16/16.
//  Copyright © 2016 purpletalk. All rights reserved.
//

import UIKit

class HeaderView: UITableViewHeaderFooterView {

    @IBOutlet weak var menuTitleCollectionView: UICollectionView!
    
    var titles: [String]? {
        didSet {
            menuTitleCollectionView?.reloadData()
        }
    }
    var selectedIndexPath: IndexPath?
    weak var delegate: HeaderProtocol?
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
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
        menuTitleCollectionView?.dataSource = self
        menuTitleCollectionView?.delegate = self
        menuTitleCollectionView?.register(MenuTitleCell.nib(), forCellWithReuseIdentifier: MenuTitleCell.cellIdentifier())
    }
    
    fileprivate func loadViewFromNib() -> UIView {
        let nib = UINib(nibName: "HeaderView", bundle: nil)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as? UIView ?? UIView()
        return view
    }
    
    func updateMenuItem(_ forIndex: Int) {
        
        if let titles_ = titles, titles_.count > 0 {
            selectedIndexPath = IndexPath(item: forIndex, section: 0)
            menuTitleCollectionView?.reloadData()
            if let selectedIndexPath_ = selectedIndexPath {
                menuTitleCollectionView?.scrollToItem(at: selectedIndexPath_, at: .centeredHorizontally, animated: true)
            }
        }
    }
    
    deinit {
        Utilities.log("HeaderView deinit" as AnyObject, type: .trace)
    }
}

extension HeaderView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (titles != nil) ? (titles?.count ?? 0) : 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MenuTitleCell.cellIdentifier(), for: indexPath) as? MenuTitleCell else {
            return UICollectionViewCell()
        }
        cell.isSelected = selectedIndexPath == indexPath ? true : false
        if let titleString = titles?[(indexPath as NSIndexPath).item], false == titleString.isEmpty {
            cell.loadCell(titleString)
        }
//        cell.loadCell(titles![(indexPath as NSIndexPath).item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var titleString = ""
        if let titleString_ = titles?[(indexPath as NSIndexPath).item], false == titleString_.isEmpty {
            titleString = titleString_
        }

        let size = getTitleSize(titleString, forIndexPath: indexPath)
        let width = size.width + 10.0
        return CGSize(width: width, height: HeaderHeight)
    }

    func getTitleSize(_ title: String, forIndexPath indexpath: IndexPath) -> CGSize {
        
        let font = selectedIndexPath == indexpath ? UIFont.montserratSemiBoldWithSize(16.0) : UIFont.montserratLightWithSize(14.0)
        
        let itemWidth = (title as NSString).boundingRect(with: CGSize(width: CGFloat(Float.greatestFiniteMagnitude), height: HeaderHeight), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        return itemWidth.size
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if selectedIndexPath != indexPath {
            
            selectedIndexPath = indexPath
            menuTitleCollectionView?.reloadData()
            if let selectedIndexPath_ = selectedIndexPath {
                menuTitleCollectionView?.scrollToItem(at: selectedIndexPath_, at: .centeredHorizontally, animated: true)
                delegate?.scrollToViewController(selectedIndexPath_.item)
            }
        }
    }
}

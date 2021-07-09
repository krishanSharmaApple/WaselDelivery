//
//  MultiLocationPopUpViewController.swift
//  WaselDelivery
//
//  Created by Purpletalk on 8/1/17.
//  Copyright © 2017 [x]cube Labs. All rights reserved.
//

import UIKit

protocol MultiLocationPopUpProtocol: class {
    func pushToDetailsScreen(selectedOutlet: Outlet, outletsInfo_: OutletsInfo)
    func removeMultiLocationPopUp()
}

class MultiLocationPopUpViewController: UIViewController {

    @IBOutlet weak var locationName: UILabel!
    @IBOutlet weak var multiLocationTableView: UITableView!
    @IBOutlet weak var doneView: UIView!
    var selectedOutletInformation: OutletsInfo?
    weak var delegate: MultiLocationPopUpProtocol?
    fileprivate var selectedCellBackgroundView = UIView()
    fileprivate var previousSelectedOutletIndex = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        multiLocationTableView.register(MultiLocationTableViewCell.nib(), forCellReuseIdentifier: MultiLocationTableViewCell.cellIdentifier())
        self.multiLocationTableView.tableFooterView = UIView()
        multiLocationTableView.estimatedRowHeight = 91.0
        multiLocationTableView.rowHeight = UITableView.automaticDimension

        selectedCellBackgroundView.backgroundColor = UIColor(red: 238.0/255.0, green: 248.0/255.0, blue: 240.0/255.0, alpha: 1.0)
        doneView.layer.shadowColor = UIColor.gray.cgColor
        doneView.layer.shadowOffset = CGSize(width: 0, height: -1.0)
        doneView.layer.shadowOpacity = 0.2
        doneView.layer.shadowRadius = 1.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let aOutlet = selectedOutletInformation?.outlet?.first {
            locationName.text = Utilities.fetchOutletName(aOutlet)
        } else {
            locationName.text = selectedOutletInformation?.location
        }
    }

// MARK: - User defined Methods
    
    func loadData() {
        DispatchQueue.main.async(execute: {
            self.multiLocationTableView.reloadData()
            if let selectedOutletIndex = self.selectedOutletInformation?.selectedOutletIndex, -1 != selectedOutletIndex {
                self.previousSelectedOutletIndex = selectedOutletIndex
                if let multiLocationTableViewCell = self.multiLocationTableView.cellForRow(at: IndexPath(row: selectedOutletIndex, section: 0)) as? MultiLocationTableViewCell {
                    multiLocationTableViewCell.setSelected(true, animated: false)
                }
            } else {
                self.previousSelectedOutletIndex = -1
            }
        })
    }

// MARK: - IBActions
    
    @IBAction func cancelMultiLocationPopupAction(_ sender: Any) {
        if let delegate_ = delegate {
            delegate_.removeMultiLocationPopUp()
        }
    }
    
    @IBAction func confirmMultiLocationPopupAction(_ sender: Any) {
        if let selectedOutletIndex = self.selectedOutletInformation?.selectedOutletIndex, -1 != selectedOutletIndex {
            if previousSelectedOutletIndex == selectedOutletIndex {
                if let delegate_ = delegate {
                    delegate_.removeMultiLocationPopUp()
                    return
                }
            }
            if let aOutLet = selectedOutletInformation?.outlet?[selectedOutletIndex] {
                if 3 == aOutLet.openStatus {//Open
                    if let delegate_ = delegate, let selectedOutletInformation_ = selectedOutletInformation {
                        delegate_.pushToDetailsScreen(selectedOutlet: aOutLet, outletsInfo_: selectedOutletInformation_)
                    }
                } else {
                    let outletStatus = Utilities.isOutletOpen(aOutLet)
                    let messageString = (2 == aOutLet.openStatus) ? OutletBusyMessage : outletStatus.message
                    Utilities.showToastWithMessage(messageString)
                }
            } else {
                Utilities.showToastWithMessage("Please select outlet location")
            }
            previousSelectedOutletIndex = selectedOutletIndex
        } else {
            Utilities.showToastWithMessage("Please select outlet location")
        }
    }

}

extension MultiLocationPopUpViewController: UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let outletsArray = self.selectedOutletInformation?.outlet {
            return outletsArray.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let multiLocationTableViewCell = tableView.dequeueReusableCell(withIdentifier: MultiLocationTableViewCell.cellIdentifier(), for: indexPath) as? MultiLocationTableViewCell else {
            return UITableViewCell()
        }
        if let aOutlet = self.selectedOutletInformation?.outlet?[indexPath.row] {
            let selectedOutletIndex = self.selectedOutletInformation?.selectedOutletIndex
            
            let filteredOutlets = self.selectedOutletInformation?.outlet?.filter {
                let aOutletName = Utilities.fetchOutletLocationName(aOutlet)
                let filteredOutletName = Utilities.fetchOutletLocationName($0)
                return aOutletName.uppercased() == filteredOutletName.uppercased()
            }
            var isDuplicatedOutlet = false
            if nil != filteredOutlets {
                isDuplicatedOutlet = (1 < filteredOutlets?.count ?? 0) ? true : false
            }
            let isOutletSelected = (selectedOutletIndex == indexPath.row) ? true : false
            multiLocationTableViewCell.loadOutletDetails(aOutlet, isOutletSelected: isOutletSelected, isDuplicatedOutlet: isDuplicatedOutlet)
        }
        multiLocationTableViewCell.selectedBackgroundView = selectedCellBackgroundView
        return multiLocationTableViewCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.selectedOutletInformation?.selectedOutletIndex == indexPath.row {
            return
        }
        self.selectedOutletInformation?.selectedOutletIndex = indexPath.row
        self.multiLocationTableView.reloadData()
        
        if let multiLocationTableViewCell = tableView.cellForRow(at: indexPath) as? MultiLocationTableViewCell {
            multiLocationTableViewCell.setSelected(true, animated: false)
        }
    }
    
}

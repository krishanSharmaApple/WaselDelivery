//
//  ManageAddressController.swift
//  WaselDelivery
//
//  Created by sunanda on 12/19/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import RxSwift

class ManageAddressController: BaseViewController, UITableViewDelegate, UITableViewDataSource, DeleteAddressProtocol {

    @IBOutlet weak var addAddressButton: UIButton!
    @IBOutlet weak var addressTableView: UITableView!
    @IBOutlet weak var navigationHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var addAddressButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var warningBgView: UIView!

    var editMode: AddressEditMode = .edit
    private var disposableBag = DisposeBag()
    
    private lazy var refreshControl: UIRefreshControl = {
        var refresh = UIRefreshControl()
        refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(self.refreshAddresses(_:)), for: .valueChanged)
        return refresh
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        Utilities.shouldHideTabCenterView(tabBarController, true)
        addNavigationView()
        self.navigationView?.titleLabel.text = "Manage Address"
        addressTableView.estimatedRowHeight = 125.0
        addressTableView.rowHeight = UITableView.automaticDimension
        navigationView?.editButton.isSelected = false
        addAddressButton.isExclusiveTouch = true
        view.isExclusiveTouch = true
        getAddresses(isSilentCall: false)
        self.addressTableView.addSubview(refreshControl)
        
        if true == Utilities.shared.isIphoneX() {
            addAddressButtonBottomConstraint.constant = 0.0
        } else {
            addAddressButtonBottomConstraint.constant = 30.0
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationHeightConstraint.constant = (true == Utilities.shared.isIphoneX()) ? 88.0 : 64.0
        self.reloadUI()
        self.addressTableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UPSHOTActivitySetup.shared.createPageViewEvent(currentPage: BKConstants.MANAGE_ADDRESS_SCREEN)
    }

    override func navigateBack(_ sender: Any?) {
        Utilities.shouldHideTabCenterView(tabBarController, false)
        super.navigateBack(nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func editAction(_ sender: UIButton?) {
        if let sender_ = sender {
            sender_.isSelected = !sender_.isSelected
            editMode = (sender_.isSelected == true) ? .done : .edit
        }
        addAddressButton.isHidden = (editMode == .edit) ? false : true
        addressTableView.reloadData()
    }
    
    deinit {
        Utilities.log(#function as AnyObject, type: .trace)
    }
    
// MARK: - API Methods
    
    private func getAddresses(isSilentCall: Bool) {
        
        if Utilities.shared.isNetworkReachable() == false {
            if self.refreshControl.isRefreshing {
                self.refreshControl.endRefreshing()
            }
        }

        getUserProfile(isSilentCall: isSilentCall).subscribe(onNext: { (_) in
            if self.refreshControl.isRefreshing {
                self.refreshControl.endRefreshing()
            }
            self.reloadUI()
            self.addressTableView.reloadData()
        }).disposed(by: disposableBag)
    }
    
    private func reloadUI() {
        if let addresses_ = Utilities.shared.user?.addresses {
            if addresses_.count > 0 {
                warningBgView.isHidden = true
                self.navigationView?.editButton.isHidden = false
            } else {
                warningBgView.isHidden = false
                self.navigationView?.editButton.isHidden = true
            }
        } else {
            warningBgView.isHidden = false
            self.navigationView?.editButton.isHidden = true
        }
    }
    
    private func delete(address: Address) {
        
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }
        guard let user_ = Utilities.shared.user, let id_ = user_.id else {
            Utilities.showToastWithMessage("User does not exist in the system")
            return
        }
        guard let addId_ = address.id else {
            Utilities.showToastWithMessage("Please select address")
            return
        }
        
        var request = [String: Any]()
        request["id"] = id_ as AnyObject
        request["address"] = [[IdKey: addId_ as AnyObject]]
        
        Utilities.showHUD(to: self.view, "")
        ApiManager.shared.apiService.deleteAddress(request as [String: AnyObject]).subscribe(onNext: { [weak self](user) in
            
            Utilities.hideHUD(from: self?.view)
            if let addresses_ = user.addresses, addresses_.count > 0 {
                self?.navigationView?.editButton.isHidden = false
                self?.warningBgView.isHidden = true
            } else {
                self?.warningBgView.isHidden = false
                self?.navigationView?.editButton.isHidden = true
                self?.editMode = .edit
                self?.addAddressButton.isHidden = (self?.editMode == .edit) ? false : true
            }
            self?.addressTableView.reloadData()

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

    @objc func refreshAddresses(_ sender: Any?) {
        getAddresses(isSilentCall: true)
    }
    
// MARK: - IBActions
    
    @IBAction func addAddress(_ sender: UIButton) {
        
        let addAddressController = AddAddressController.instantiateFromStoryBoard(.checkOut)
        addAddressController.isFromProfile = true
        navigationController?.pushViewController(addAddressController, animated: true)
    }
    
// MARK: - UITableViewDelegate & Datasource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let user_ = Utilities.shared.user, let addresses_ = user_.addresses {
            return addresses_.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AddAddressCell.cellIdentifier(), for: indexPath) as? AddAddressCell else {
            return UITableViewCell()
        }
        guard let addresses = Utilities.shared.user?.addresses else {
            return UITableViewCell()
        }
        cell.loadAddress(address: addresses[indexPath.row], editMode: editMode)
        cell.delegate = self
        return cell
    }
    
// MARK: - DeleteAddressProtocol
    
    func deleteAddress(address: Address) {
        let popupVC = PopupViewController()
        let responder = popupVC.showAlert(viewcontroller: self, title: "Are you sure?", text: "Do you really want to delete this address from your list?", buttonText: "NO", cancelButtonText: "YES")
        responder.addCancelAction({
            DispatchQueue.main.async(execute: {
                self.delete(address: address)
            })
        })
    }
}

class AddAddressCell: UITableViewCell {
    
    @IBOutlet weak var addressImageView: UIImageView!
    @IBOutlet weak var addressTitleLabel: UILabel!
    @IBOutlet weak var addressDescriptionLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    
    @IBOutlet weak var addressTypeView: UIView!
    @IBOutlet weak var detailLeadingConstraint: NSLayoutConstraint!
    weak var delegate: DeleteAddressProtocol?
    var address: Address!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        deleteButton.isExclusiveTouch = true
        addressImageView.tintColor = UIColor(red: 134.0/255.0, green: 134.0/255.0, blue: 134.0/255.0, alpha: 1.0)
    }
    
    class func cellIdentifier() -> String {
        return "AddAddressCell"
    }
    
    func loadAddress(address: Address, editMode: AddressEditMode) {
        
        self.address = address
        addressDescriptionLabel.text = address.getAddressString()
        
        if editMode == .edit {
            if let adddressType_ = address.addressType {
                switch adddressType_ {
                case "HOME":
                    addressImageView.image = UIImage(named: "homeOFF")
                case "OFFICE":
                    addressImageView.image = UIImage(named: "workOFF")
                default:
                    addressImageView.image = UIImage(named: "othersOFF")
                }
                addressTitleLabel.text = adddressType_.capitalized
            }
        }
        addressTypeView.isHidden = (editMode == .edit) ? false : true
        deleteButton.isHidden = (editMode == .edit) ? true : false
        detailLeadingConstraint.constant = (editMode == .edit) ? 20.0 : 90.0
        self.contentView.layoutIfNeeded()
    }
    
// MARK: - IBActions
    
    @IBAction func deleteAddress(_ sender: UIButton) {
        if let delegate_ = delegate {
            delegate_.deleteAddress(address: address)
        }
    }
}

protocol DeleteAddressProtocol: class {
    func deleteAddress(address: Address)
}

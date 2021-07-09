//
//  EditProfileController.swift
//  WaselDelivery
//
//  Created by sunanda on 12/20/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import RxSwift
import SDWebImage
import MobileCoreServices
import Toaster
import AVFoundation

struct EditProfile {
    var name: String = ""
    let mobile: String!
    var image: UIImage?
    var email: String = ""
    
    var isProfileEdited: Bool {
        guard let user_ = Utilities.shared.user else {
            return false
        }
        if name != user_.name ?? "" || (email != user_.email ?? "" && Utilities.isValidEmail(testStr: email)) {
            return true
        }
        return false
    }
    
    var isImageEdited: Bool {
        if nil != image {
            return true
        }
        return false
    }

    init(user: User) {
        name = user.name ?? ""
        email = user.email ?? ""
        mobile = user.mobile ?? ""
    }
}

enum EditProfileTextField: Int {
    case name
    case phoneNumber
    case email
}

class EditProfileController: BaseViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    @IBOutlet weak var profileTableView: UITableView!
    @IBOutlet weak var tableBotomConstraint: NSLayoutConstraint!
    @IBOutlet weak var navigationHeightConstraint: NSLayoutConstraint!

    private lazy var imagePicker: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.allowsEditing = true
        return picker
    }()
    
    private lazy var cameraPicker: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.allowsEditing = true
        return picker
    }()
    
    private var newMedia: Bool?
    private var editProfile: EditProfile!
    private var disposableBag = DisposeBag()
    private var shouldUpdate = false
    var showNotification: Any!
    var hideNotification: Any!
    fileprivate var currenTextFieldTag = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let user_ = Utilities.shared.user {
            editProfile = EditProfile(user: user_)
        }
        addNavigationView()
        navigationView?.titleLabel.text = "Edit Profile"
        customiseNavigationView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationHeightConstraint.constant = (true == Utilities.shared.isIphoneX()) ? 88.0 : 64.0
        /*showNotification = registerForKeyboardDidShowNotification(tableBotomConstraint, 0.0, shouldUseTabHeight: false, usingBlock: { _ in
            DispatchQueue.main.async(execute: {
                self.profileTableView.scrollToRow(at: IndexPath(row: self.currenTextFieldTag, section: 0), at: .none, animated: true)
            })
        })
        hideNotification = registerForKeyboardWillHideNotification(tableBotomConstraint)*/
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(showNotification)
        NotificationCenter.default.removeObserver(hideNotification)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UPSHOTActivitySetup.shared.createPageViewEvent(currentPage: BKConstants.EDIT_PROFILE_SCREEN)
    }

    deinit {
        Utilities.log(#function as AnyObject, type: .trace)
    }
    
    override func navigateBack(_ sender: Any?) {
        
        view.endEditing(true)
        
        if editProfile.isProfileEdited || editProfile.isImageEdited {
            
            let popupVC = PopupViewController()
            let responder = popupVC.showAlert(viewcontroller: self, title: "Wasel Delivery", text: "Would you like to save these changes?", buttonText: "Discard", cancelButtonText: "Save")
            
            responder.setDismissButtonColor(.alertColor())
            responder.setCancelButtonColor(.white)
            
            responder.setDismissTitleColor(.white)
            responder.setCancelTitleColor(.unSelectedTextColor())
            
            responder.setDismissButtonBorderColor(.white)
            responder.setCancelButtonBorderColor(.unSelectedTextColor())
            
            responder.addAction({
                DispatchQueue.main.async(execute: {
                    self.dismiss(animated: true, completion: nil)
                })
            })
            responder.addCancelAction({ 
                DispatchQueue.main.async(execute: {
                    self.editAction(nil)
                })
            })
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    override func editAction(_ sender: UIButton?) {
        // call save profile api
        view.endEditing(true)
        
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }

        if editProfile.isProfileEdited {
            if editProfile.name.length > 0 && editProfile.email.length > 0 {
                if editProfile.isImageEdited {
                    uploadImage()
                } else {
                    Utilities.showHUD(to: self.view, "")
                    updateProfile(imageURL: nil)
                }
            } else {
                if editProfile.name.length == 0 && editProfile.email.length == 0 {
                    Utilities.showToastWithMessage("Please enter name and email.")
                } else if editProfile.name.length == 0 {
                    Utilities.showToastWithMessage("Please enter a name.")
                } else {
                    Utilities.showToastWithMessage("Please enter a email.")
                }
            }
        } else if editProfile.isImageEdited {
            uploadImage()
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
// MARK: - Support Methods
    
    private func uploadImage() {
        
        guard let userId_ = Utilities.shared.user?.id else {
            return
        }
        guard let editProfileImage = editProfile.image else {
            return
        }
        var requestObj: [String: Any] = [UserIdKey: userId_]
        let image_data = editProfileImage.jpegData(compressionQuality: 0.75)
        requestObj["imageData"] = image_data
        
        Utilities.showHUD(to: self.view, "")
        ApiManager.shared.apiService.updateProfileImage(requestObj as [String: AnyObject]).subscribe(onNext: { [weak self](result) in

            let user = result
            guard user.imageUrl != nil else {
                Utilities.showToastWithMessage("Image Upload failed")
                return
            }
            self?.updateProfile(imageURL: user.imageUrl ?? "")
            
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
    
    private func updateProfile(imageURL: String?) {
        
        guard Utilities.isValidEmail(testStr: editProfile.email) else {
            Utilities.hideHUD(from: view)
            Utilities.showToastWithMessage("Please enter valid email.")
            return
        }
        
        var request = [String: Any]()
        if let imageURL_ = imageURL {
            request[ImageURLKey] = imageURL_ as AnyObject
        }
        if editProfile.name.length > 0 {
            request[NameKey] = editProfile.name as AnyObject
        }
        if editProfile.email.length > 0 {
            request[EmailKey] = editProfile.email as AnyObject
        }
        
        if request.keys.count > 0 {
            request[IdKey] = Utilities.shared.user?.id ?? "" as AnyObject
            
            ApiManager.shared.apiService.updateProfile(request as [String: AnyObject]).subscribe(onNext: { [weak self](_) in
                
                Utilities.hideHUD(from: self?.view)
                self?.dismiss(animated: true, completion: nil)
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
            }).disposed(by: self.disposableBag)
        }
    }
    
    private func customiseNavigationView() {
        navigationView?.backButton.isHidden = false
        
        navigationView?.editButton.setTitle("Save", for: .normal)
        navigationView?.editButton.titleLabel?.font = UIFont.montserratSemiBoldWithSize(14.0)
        navigationView?.editButton.setTitleColor(UIColor(red: (60.0/255.0), green: (60.0/255.0), blue: (60.0/255.0), alpha: 1.0), for: .normal)
        navigationView?.editButton.setTitle("", for: .selected)
        navigationView?.editButton.isHidden = false
    }
    
// MARK: - IBActions
    
    @IBAction func changeImage(_ sender: UIButton) {
        
        let optionMenu = UIAlertController(title: nil, message: "Choose Option", preferredStyle: .actionSheet)

        let cameraAction = UIAlertAction(title: "Camera", style: .default, handler: { (_: UIAlertAction!) -> Void in
            self.showCamera()
        })
        let libraryAction = UIAlertAction(title: "Photo Library", style: .default, handler: { (_: UIAlertAction!) -> Void in
            self.showPhotoLibrary()
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (_: UIAlertAction!) -> Void in
        })
        optionMenu.addAction(cameraAction)
        optionMenu.addAction(libraryAction)
        optionMenu.addAction(cancelAction)
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    private func showCamera() {
        
        let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch authStatus {
        case .authorized:
            self.present(self.cameraPicker, animated: true, completion: nil)
        case .denied:
            alertToAccessCamera()
        case .notDetermined:
            requestCameraAccess()
        case .restricted:
            alertToAccessCamera()
        }
    }
    
    func alertToAccessCamera() {
        let alert = UIAlertController(
            title: "Wasel Delivery",
            message: "Camera access required for capturing photos.",
            preferredStyle: UIAlertController.Style.alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Allow", style: .cancel, handler: { (_) -> Void in
            UIApplication.shared.openURL(URL(string: UIApplication.openSettingsURLString) ?? URL(fileURLWithPath: ""))
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func requestCameraAccess() {
        
        if AVCaptureDevice.devices(for: AVMediaType.video).count > 0 {
            AVCaptureDevice.requestAccess(for: AVMediaType.video) { _ in
                DispatchQueue.main.async {
                    self.showCamera()
                }
            }
        }
    }
    
    private func showPhotoLibrary() {
        self.imagePicker.mediaTypes = [kUTTypeImage as String]
        self.present(self.imagePicker, animated: true, completion: nil)
    }
    
// MARK: - UITAbleVeiwDelegate&Datasource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 176.0
        }
        return 80.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: EditProfileImageCell.cellIdentifier(), for: indexPath) as? EditProfileImageCell else {
                return UITableViewCell()
            }
            if shouldUpdate == true {
                cell.updateProfileImage(image_: editProfile.image)
            } else {
                cell.loadUserDetails()
            }
            return cell
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: EditProfileCell.cellIdentifier(), for: indexPath) as? EditProfileCell else {
            return UITableViewCell()
        }
        cell.textField.delegate = self
        cell.loadUserDetails(profile: editProfile, index: indexPath.row)
        return cell
    }

// MARK: - UITextViewDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentCharacterCount = textField.text?.count ?? 0
        if range.length + range.location > currentCharacterCount {
            return false
        }
        let newLength = currentCharacterCount + string.count - range.length

        if textField.tag == EditProfileTextField.phoneNumber.rawValue {
            return Utilities.shared.isValidCharacterForName(textField: textField, string: string, forLength: newLength)
        } else if textField.tag == EditProfileTextField.phoneNumber.rawValue {
            let charactesAllowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 ")
            let isSpace = (string.isEmpty) ? true : false
            var isStringOrCharacterAllowed = false
            if nil != string.rangeOfCharacter(from: charactesAllowed) {
                isStringOrCharacterAllowed = true
            } else {
                isStringOrCharacterAllowed = false
            }
            let isValidCharacter = (isStringOrCharacterAllowed || (isSpace == true)) ? true : false
            return isValidCharacter && newLength <= MaxNameCharacters
        } else {
            return newLength <= MaxEmailCharacters//isValidCharacterForEmail(textField: textField, string: string, forLength: newLength)
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.tag == 1 {
            editProfile.name = textField.text?.trim().capitalized ?? ""
        } else if textField.tag == 3 {
            editProfile.email = textField.text?.trim() ?? ""
        }
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField.tag == 2 {
            return false
        }
        currenTextFieldTag = textField.tag
        return true
    }
    
// MARK: - PickerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        self.dismiss(animated: true, completion: nil)
        let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
        if let image_ = image {
            let resizedImage = image_.resizeImage(newWidth: 200.0)
            shouldUpdate = true
            editProfile.image = resizedImage
            profileTableView.reloadData()
        }
    }
    
    func image(image: UIImage, didFinishSavingWithError error: NSErrorPointer, contextInfo: UnsafeRawPointer) {
        
        Utilities.showToastWithMessage("Failed to save image")
        if error != nil {
            let alert = UIAlertController(title: "Save Failed",
                                          message: "Failed to save image",
                                          preferredStyle: UIAlertController.Style.alert)
            let cancelAction = UIAlertAction(title: "OK",
                                             style: .cancel,
                                             handler: nil)
            alert.addAction(cancelAction)
            self.present(alert,
                         animated: true,
                         completion: nil)
        }
    }
}

class EditProfileCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    
    class func cellIdentifier() -> String {
        return "EditProfileCell"
    }
    
    func loadUserDetails(profile: EditProfile, index: Int) {
        
        textField.textColor = UIColor.selectedTextColor()
        
            switch index {
            case 1:
                titleLabel.text = "Name"
                textField.text = profile.name
            case 2:
                titleLabel.text = "Phone Number"
                textField.text = profile.mobile
                textField.textColor = UIColor.unSelectedTextColor()
            default:
                titleLabel.text = "Email ID"
                textField.text = profile.email
            }
            textField.tag = index
    }
}

class EditProfileImageCell: UITableViewCell {
    
    @IBOutlet weak var profileImageView: UIImageView!

    class func cellIdentifier() -> String {
        return "EditProfileImageCell"
    }

    func loadUserDetails() {
        
        let user = Utilities.shared.user
        if let user_ = user, let imageurl_ = user_.imageUrl {
            let image = imageBaseUrl + imageurl_
            profileImageView.sd_setImage(with: URL(string: image), placeholderImage: UIImage(named: "profile_placeholder"))
        }
    }
    
    func updateProfileImage(image_: UIImage?) {
        if let profileImage_ = image_ {
            profileImageView.image = profileImage_
        } else {
            profileImageView.image = UIImage(named: "profile_placeholder")
        }
    }

}

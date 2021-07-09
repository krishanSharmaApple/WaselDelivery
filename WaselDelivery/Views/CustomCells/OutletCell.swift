//
//  OutletCell.swift
//  WaselDelivery
//
//  Created by sunanda on 11/17/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import SDWebImage
import KDCircularProgress

class OutletCell: UITableViewCell {
    
    @IBOutlet weak var subTitleHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var availableTimingLabel: UILabel!
    @IBOutlet weak var timingLabel: UILabel!
    @IBOutlet weak var timeView: UIView!
    @IBOutlet weak var timeShiftView: UIView!
    @IBOutlet weak var partnerLabel: UILabel!
    @IBOutlet weak var closingTimeLabel: UILabel!
    @IBOutlet weak var busyLabel: UILabel!

    @IBOutlet weak var outletImageView: UIImageView!
    @IBOutlet weak var outletTitleLabel: UILabel!
    @IBOutlet weak var outletSubTitleLabel: UILabel!
    @IBOutlet weak var outletDistanceLabel: UILabel!
    @IBOutlet weak var outletCostLabel: UILabel!
    @IBOutlet weak var outletPricesLabel: UILabel!
    @IBOutlet weak var closingContainerView: UIView!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var minLabel: UILabel!
    @IBOutlet weak var distanceContainerView: UIView!
    @IBOutlet weak var kmBDLabel: UILabel!
    @IBOutlet weak var deliveryChargeLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!

    var shoulAllowSelection = true
    var applyGradient = false
    fileprivate var timer: Timer?
    private var restaurant: Outlet!
    var progress: KDCircularProgress!
    weak var closingInMinUpdateDelegate: ClosingInMinUpdateProtocol?
    var timerCount = 0 {
        didSet {
            if timerCount == 120 {
                timerCount = 0
                timerNotification()
            }
        }
    }

    @IBOutlet var gradientViews: [UIView]!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.applyCornerRadiusOnPartnerLabel()
        self.applyCornerRadiusOnClosingTimeLabel()
        self.applyCornerRadiusOnBusyLabel()
        self.busyLabel.alpha = 0.0
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateAnimation), name: NSNotification.Name(rawValue: UpdateStatusAnimationNotification), object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(updateAllAnimation), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)

        progress = KDCircularProgress(frame: progressView.bounds)
        progress.startAngle = -90
        progress.progressThickness = 0.2
        progress.trackThickness = 0.2
        progress.clockwise = true
        progress.roundedCorners = true
        progress.glowMode = .noGlow
//        progress.glowAmount = 0.9
        progress.progressInsideFillColor = UIColor(red: (0.0/255.0), green: (0.0/255.0), blue: (0.0/255.0), alpha: 0.35)
        progress.set(colors: UIColor(red: (85.0/255.0), green: (190.0/255.0), blue: (109.0/255.0), alpha: 1.0))
        progress.trackColor = UIColor(red: (0.0/255.0), green: (0.0/255.0), blue: (0.0/255.0), alpha: 1.0)
        progressView.addSubview(progress)
        progressView.isHidden = true
        closingContainerView.isHidden = true
        progressView.bringSubviewToFront(minLabel)
        self.bringSubviewToFront(progressView)

        self.showProgress(rotationValue: 0)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(UpdateStatusAnimationNotification), object: nil)
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }

    override func draw(_ rect: CGRect) {
        
        if applyGradient == false {
            applyGradient = true
            let gradient1: CAGradientLayer = CAGradientLayer()
            gradient1.frame.size = CGSize(width: ScreenWidth, height: rect.height - 2.0)
            gradient1.colors = [UIColor(red: (56.0/255.0), green: (56.0/255.0), blue: (56.0/255.0), alpha: 0.0).cgColor, UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.9).cgColor]
            gradientViews[0].layer.addSublayer(gradient1)
            
            let gradient2: CAGradientLayer = CAGradientLayer()
            gradient2.frame.size = CGSize(width: ScreenWidth, height: rect.height - 2.0)
            gradient2.colors = [UIColor(red: (56.0/255.0), green: (56.0/255.0), blue: (56.0/255.0), alpha: 0.0).cgColor, UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0).cgColor]
            gradientViews[1].layer.addSublayer(gradient2)
        }
    }
    
    @objc private func updateAllAnimation() {
        self.updateAnimation()
        self.updateClosingInMinsLabelAnimation()
    }
    
    @objc private func updateAnimation() {
        timerCount += 1
        if 2 == restaurant.openStatus {
            UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseIn, animations: {
                self.busyLabel.alpha = (self.busyLabel.alpha == 1.0) ? 0.0 : 1.0
            }, completion: nil)
        }
    }
    
    @objc private func updateClosingInMinsLabelAnimation() {
        UIView.animate(withDuration: 1.0, delay: 0.0, options: [.autoreverse, .repeat], animations: {
            self.minLabel.alpha = (self.minLabel.alpha == 1.0) ? 0.0 : 1.0
        }, completion: nil)
    }
    
    private func applyCornerRadiusOnPartnerLabel() {
        let path = UIBezierPath(roundedRect: partnerLabel.bounds,
                                byRoundingCorners: [.topRight, .bottomRight],
                                cornerRadii: CGSize(width: 5, height: 5))
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        partnerLabel.layer.mask = maskLayer
    }
    
    private func applyCornerRadiusOnClosingTimeLabel() {
        closingTimeLabel.clipsToBounds = true
        let path = UIBezierPath(roundedRect: closingTimeLabel.bounds,
                                byRoundingCorners: [.topLeft, .bottomLeft],
                                cornerRadii: CGSize(width: 5, height: 5))
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        closingTimeLabel.layer.mask = maskLayer
    }

    private func applyCornerRadiusOnBusyLabel() {
        let path = UIBezierPath(roundedRect: busyLabel.bounds,
                                byRoundingCorners: [.topLeft, .bottomLeft, .topRight, .bottomRight],
                                cornerRadii: CGSize(width: 5, height: 5))
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        busyLabel.layer.mask = maskLayer
    }

    class func cellIdentifier() -> String {
        return "OutletCell"
    }
    
    func loadOutletDetails(_ restaurant: OutletsInfo, _ amenity: Amenity) {
        if let aOutlet = restaurant.outlet?.first {
            self.restaurant = aOutlet
            outletTitleLabel.text = Utilities.fetchOutletName(aOutlet).trim()
//            if let name_ = aOutlet.name { //restaurant.location
//                outletTitleLabel.text = name_.trim()
//            }
//            else {
//                outletTitleLabel.text = ""
//            }

            distanceLabel.attributedText = Utilities.getDistanceAttString(outlet: aOutlet)

            if let description_ = self.restaurant.description {
                outletSubTitleLabel.text = description_.trim()
                let height = Utilities.getSizeForText(text: description_, font: .montserratRegularWithSize(12.0), fixedWidth: ScreenWidth - 10.0).height
                subTitleHeightConstraint.constant = height
            } else {
                outletSubTitleLabel.text = ""
                subTitleHeightConstraint.constant = 0.0
            }
            
            /*outletDistanceLabel.attributedText = Utilities.getDistanceAttString(outlet: self.restaurant)
            
            if true == self.restaurant.isFleetOutLet {
                outletCostLabel.attributedText = NSAttributedString(string: self.restaurant.ownFleetDescription ?? "")
            } else {
                outletCostLabel.attributedText = Utilities.getDeliveryChargeAttString(outlet: self.restaurant)
            }*/

            // "Min-Order: BD 0.000 | Handling Fee: BD 0.000 | Delivery Fee: BD 0.000"

            let minOrderString = Utilities.getMinimumOrderStringFrom(outlet: self.restaurant)
            let handlingFeeString = Utilities.getHandleFeeStringFrom(outlet: self.restaurant)
            var pricesString = minOrderString.isEmpty ? "" : minOrderString
            if !handlingFeeString.isEmpty {
                pricesString += pricesString.isEmpty ? "" : " | "
                pricesString += handlingFeeString
            }
            outletPricesLabel.text = pricesString

            let deliveryChargeString = Utilities.getDeliveryChargeStringFrom(outlet: self.restaurant)
            deliveryChargeLabel.text = deliveryChargeString
            if Double(deliveryChargeString) == nil {
                kmBDLabel.text = " |"
            } else {
                kmBDLabel.text = " | BD"
            }

            if let imageUrl_ = self.restaurant.imageUrl {
                outletImageView.sd_setImage(with: URL(string: imageUrl_), placeholderImage: UIImage(named: "outlet_placeholder"))
            } else {
                outletImageView.image = UIImage(named: "outlet_placeholder")
            }
            
            if true == self.restaurant.isPartnerOutLet {
                self.partnerLabel.isHidden = false
            } else {
                self.partnerLabel.isHidden = true
            }
            self.busyLabel.isHidden = (2 == self.restaurant.openStatus) ? false : true //openStatus-> 1: closed, 2: Busy, 3: Open
            
            let outletStatus = Utilities.isOutletOpen(self.restaurant)
            if 3 == self.restaurant.openStatus {//Open
                if let outLetClosingTimeInMins = self.restaurant.closingTimeInMins, 60 >= outLetClosingTimeInMins {
                    closingTimeLabel.isHidden = false
                    progressView.isHidden = false
                    closingContainerView.isHidden = false
                    timerCount = 120
                } else {
                    progressView.isHidden = true
                    closingTimeLabel.isHidden = true
                    closingContainerView.isHidden = true
                    timerCount = 0
                }
//                self.timerNotification()
//                self.startTimer()
            } else {
                progressView.isHidden = true
                closingTimeLabel.isHidden = true
                closingContainerView.isHidden = true
                timerCount = 0
            }
            
            var messageString = outletStatus.message
            if 2 == self.restaurant.openStatus { // Busy
                messageString = OutletBusyMessage
            }
            showTimings(shouldShowBanner: (3 == self.restaurant.openStatus) ? false : true, timeString: messageString)
            shoulAllowSelection = (3 == self.restaurant.openStatus) ? true : false //outletStatus.isOpen
            
            if 2 == self.restaurant.openStatus { // Busy
                timeShiftView.alpha = 1.0
                timeShiftView.backgroundColor = .clear
            }
            
            outletTitleLabel.alpha = (shoulAllowSelection == true) ? 1.0 : 0.5
            outletSubTitleLabel.alpha = (shoulAllowSelection == true) ? 1.0 : 0.5
            outletDistanceLabel.alpha = (shoulAllowSelection == true) ? 1.0 : 0.5
            outletPricesLabel.alpha = (shoulAllowSelection == true) ? 1.0 : 0.5
            outletCostLabel.alpha = (shoulAllowSelection == true) ? 1.0 : 0.5
            self.updateClosingInMinsLabelAnimation()
            contentView.setNeedsLayout()
        }
    }
    
    func showProgress(rotationValue: Double) {
        progressView.isHidden = false
        closingContainerView.isHidden = false
        progress.animate(toAngle: rotationValue, duration: 0.5, completion: nil)
    }
    
    func showTimings(shouldShowBanner: Bool, timeString: String = "") {
        
        timeShiftView.alpha = (shouldShowBanner == false) ? 1.0 : 0.6
        timeShiftView.backgroundColor = (shouldShowBanner == false) ? .clear : .white
        availableTimingLabel.isHidden = !shouldShowBanner
        availableTimingLabel.text = timeString
    }
    
    private func startTimer() {
        cancelTimer()
        timer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(timerNotification), userInfo: nil, repeats: true)
        if let timer_ = timer {
            RunLoop.current.add(timer_, forMode: RunLoop.Mode.common)
        }
    }
    
    private func cancelTimer() {
        if let timer_ = timer, timer_.isValid {
            timer?.invalidate()
        }
    }
    
    private func cancelOutLetTimer() {
//        cancelTimer()
        closingTimeLabel.isHidden = true
        progressView.isHidden = true
        closingContainerView.isHidden = true
    }
    
    @objc func timerNotification() {
        if let closingInMinUpdateDelegate_ = closingInMinUpdateDelegate {
            closingInMinUpdateDelegate_.updateCloseInMin()
        }

        if -1 >= self.restaurant.updateOutLetClosingTime() {
            cancelOutLetTimer()
        } else {
            let timeDuration = self.restaurant.updateOutLetClosingTime()
            if 0 < timeDuration {
                if 60 < timeDuration {
                    progressView.isHidden = true
                    closingTimeLabel.isHidden = true
                    closingContainerView.isHidden = true
                    return
                }
                closingTimeLabel.isHidden = false
                progressView.isHidden = false
                closingContainerView.isHidden = false
                minLabel.text = String(timeDuration) + "\n" + NSLocalizedString("MIN", comment: "")
                
                // 60Mins=360Degrees, 1Min = 6Degrees
                let rotationVal: Double = Double((60 - timeDuration) * 6)
                self.showProgress(rotationValue: rotationVal)
            } else {
                cancelOutLetTimer()
            }
        }
    }

}

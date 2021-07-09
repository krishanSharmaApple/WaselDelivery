//
//  CostDetailCell.swift
//  WaselDelivery
//
//  Created by sunanda on 3/8/17.
//  Copyright © 2017 [x]cube Labs. All rights reserved.
//

import UIKit

class CostDetailCell: UITableViewCell {

    @IBOutlet var discountLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var costLabel: UILabel!
    @IBOutlet var bdImageView: UIImageView!
    
    class func cellIdentifier() -> String {
        return "CostDetailCell"
    }
    
    func loadCost(costStruct: CostStruct, index: Int, outlet: Outlet? = nil, isGrandTotal: Bool = false) {
        var alpha: CGFloat = 0.6
        var titleFont = UIFont.montserratRegularWithSize(14.0)
        var costFont = UIFont.montserratLightWithSize(20.0)
        var bdImage = UIImage(named: "normalBD")
        let orderChargeCellIndex = 0
        let deliveryChargeCellIndex = 1
        
        let costDetailsData = costStruct.getCostDetailsDataForCell(index: index, outlet: outlet)
        bdImageView.image = bdImage
        titleLabel.text = costDetailsData.titleString
        costLabel.text = costDetailsData.priceString
        bdImageView.isHidden = !costDetailsData.showBDImage
        discountLabel.isHidden = costDetailsData.hideDiscountLabel

        if costDetailsData.titleString == "Handling Fee" && costDetailsData.priceString.contains("%") {
            costFont = UIFont.montserratLightWithSize(11)
        }

        switch index {
        case orderChargeCellIndex,
             deliveryChargeCellIndex:
            break
        default:
            // Set the Grand total fonts and images
            if true == isGrandTotal {
                alpha = 1.0
                titleFont = UIFont.montserratBoldWithSize(16.0)
                costFont = UIFont.montserratRegularWithSize(30.0)
                bdImage = UIImage(named: "totalBD")
            }
        }
        titleLabel.alpha = alpha
        costLabel.alpha = alpha
        titleLabel.font = titleFont
        costLabel.font = costFont
        bdImageView.image = bdImage
    }
    
    func updateTitleAndCostLabelsUI() {
        let alpha: CGFloat = 0.6
        let titleFont = UIFont.montserratRegularWithSize(14.0)
        let costFont = UIFont.montserratLightWithSize(20.0)

        titleLabel.alpha = alpha
        costLabel.alpha = alpha
        titleLabel.font = titleFont
        costLabel.font = costFont
    }

}

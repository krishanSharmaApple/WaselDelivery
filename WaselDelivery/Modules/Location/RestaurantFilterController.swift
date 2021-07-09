////
////  RestaurantFilterController.swift
////  WaselDelivery
////
////  Created by sunanda on 9/26/16.
////  Copyright © 2016 [x]cube Labs. All rights reserved.
////
//
// import UIKit
//
// class RestaurantFilterController: BaseViewController {
//
//    @IBOutlet weak var filterTableView: UITableView!
//    @IBOutlet weak var doneButton: UIButton!
//
//    var cuisines = [Cuisine]()
//    var restaurantFilter = RestaurantFilter()
//    var headerTitles = ["Sort By", "Select Budget", "Popular Cuisine"]
//    var delegate: RestaurantFilterProtocol?
//    
////MARK: - View LifeCycle
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        filterTableView.register(FilterSortCell.nib(), forCellReuseIdentifier: FilterSortCell.cellIdentifier())
//        filterTableView.register(FilterBudgetCell.nib(), forCellReuseIdentifier: FilterBudgetCell.cellIdentifier())
//        filterTableView.register(FilterCuisineCell.nib(), forCellReuseIdentifier: FilterCuisineCell.cellIdentifier())
//        filterTableView.tableFooterView = UIView(frame: CGRect.zero)
//        if Utilities.shared.filterCusines.count > 0 {
//            cuisines = Utilities.shared.filterCusines
//        } else {
//            getCuisines()
//        }
//    }
//
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        cancelRequest ()
//    }
//    
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//    }
//    
////MARK: - IBActions
//    
//    @IBAction func dismiss(_ sender: AnyObject) {
//
//        delegate?.updateFilter(restaurantFilter)
//        self.dismiss(animated: true, completion: nil)
//    }
//    
//    @IBAction func clearFilter(_ sender: AnyObject) {
//
//        doneButton.setTitle("Done", for: UIControlState())
//        restaurantFilter = RestaurantFilter()
//        for cuisine in cuisines {
//            cuisine.isFilterCusineSelected = false
//        }
//        print(restaurantFilter)
//        filterTableView.reloadData()
//    }
//    
////MARK: - Support Methods
//    
//    func cancelRequest() {
////        if cuisineRequest != nil {
////            cuisineRequest?.cancel()
////        }
//    }
//    
////MARK: - API Methods
//    
//    func getCuisines() {
//        
//        if Utilities.shared.isNetworkReachable() {
//            Utilities.showHUD("Loading Cuisines...")
//            let obCusines = ApiManager.shared.apiService.getCuisines()
//            _ = obCusines.subscribe(onNext: { (cuisines) in
//                self.updateCuisines(cuisines)
//                }, onError: { (error) in
//                    Utilities.hideHUD()
//                    //handle error
//                    if let error_ = error as? ResponseError {
//                        Utilities.showToastWithMessage(error_.description())
//                    }
//                }, onCompleted: {
//                    Utilities.hideHUD()
//            })
//        } else {
//            showNoInternetMessage()
//        }
//    }
//    
//    func updateCuisines(_ cuisines:[Cuisine]) {
//        DispatchQueue.main.async(execute: {
//            Utilities.hideHUD()
//            self.cuisines = cuisines
//            Utilities.shared.filterCusines = cuisines
//            self.filterTableView.reloadData()
//        })
//    }
//    
//}
//
// extension RestaurantFilterController: UITableViewDelegate, UITableViewDataSource, FilterBudgetCellProtocol, FilterSortCellProtocol {
//    
//    func numberOfSections(in tableView: UITableView) -> Int {
//        return headerTitles.count
//    }
//    
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        
//        switch section {
//        case 0: fallthrough
//        case 1:
//            return 1
//        case 2:
//            return cuisines.count
//        default:
//            return 0
//        }
//    }
//    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        
//        switch (indexPath as NSIndexPath).section {
//        case 0:
//            let cell = tableView.dequeueReusableCell(withIdentifier: FilterSortCell.cellIdentifier(), for: indexPath) as! FilterSortCell
//            cell.updateSort(restaurantFilter.isSortSelected)
//            cell.delegate = self
//            return cell
//        case 1:
//            let cell = tableView.dequeueReusableCell(withIdentifier: FilterBudgetCell.cellIdentifier(), for: indexPath) as! FilterBudgetCell
//            cell.updateBudget(restaurantFilter.selectedBudget)
//            cell.delegate = self
//            return cell
//        default:
//            let cell = tableView.dequeueReusableCell(withIdentifier: FilterCuisineCell.cellIdentifier(), for: indexPath) as! FilterCuisineCell
//            cell.updateCusine(cuisines[(indexPath as NSIndexPath).row])
//            return cell
//        }
//    }
//    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        
//        let height:CGFloat = ((indexPath as NSIndexPath).section == 1) ? 60.0 : 40.0
//        return height
//    }
//    
//    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        
//        let height:CGFloat = (section == 0) ? 48.0 : 66.0
//        return height
//    }
//    
//    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        
//        let height:CGFloat = (section == 0) ? 48.0 : 66.0
//        let labelY:CGFloat = (section == 0) ? 13.0 : 36.0
//        let labelText = headerTitles[section]
//        let headerView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: ScreenWidth, height: height))
//        headerView.backgroundColor = UIColor.white
//        let headerlabel = UILabel(frame: CGRect(x: 20.0, y: labelY, width: ScreenWidth - 40.0, height: 20.0))
//        headerlabel.font = UIFont.montserratRegularWithSize(12.0)
//        headerlabel.textColor = UIColor.selectedTextColor()
//        headerlabel.textAlignment = .left
//        headerlabel.text = labelText
//        headerView.addSubview(headerlabel)
//        return headerView
//    }
//    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        if (indexPath as NSIndexPath).section == 2 {
//            let cell = filterTableView.cellForRow(at: indexPath) as! FilterCuisineCell
//            let cuisine = cuisines[(indexPath as NSIndexPath).row]
//            cuisine.isFilterCusineSelected = !cuisine.isFilterCusineSelected
//            cell.updateCusine(cuisine)
//            updateFilterDictionaryWithCuisine(cuisines[(indexPath as NSIndexPath).row])
//        }
//        
//    }
//
//    func updateFilterDictionaryWithCuisine(_ cuisine: Cuisine) {
//        
//        if cuisine.isFilterCusineSelected! {
//            restaurantFilter.selectedCuisines.append(cuisine.id)
//        } else {
//            restaurantFilter.selectedCuisines = restaurantFilter.selectedCuisines.filter { $0 != cuisine.id }
//        }
//        updateFilterButton()
//    }
//    
//    func updateFilterDictionaryWithBudget(_ button: UIButton) {
//        if button.isSelected {
//            restaurantFilter.selectedBudget.append(button.tag)
//        } else {
//            restaurantFilter.selectedBudget = restaurantFilter.selectedBudget.filter { $0 != button.tag }
//        }
//        updateFilterButton()
//    }
//    
//    func updateFilterDictionaryWithRating(_ isSelected: Bool) {
//        restaurantFilter.isSortSelected = isSelected
//        updateFilterButton()
//    }
//
//    func updateFilterButton() {
//        
//        doneButton.setTitle(restaurantFilter.isFilterApplied ? "Apply".localized : "Done".localized, for: UIControlState())
//    }
//}
//
// protocol RestaurantFilterProtocol {
//    
//    func updateFilter(_ aFilter: RestaurantFilter)
//}
//

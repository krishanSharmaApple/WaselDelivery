//
//  SearchHistoryViewController.swift
//  WaselDelivery
//
//  Created by Karthik on 28/11/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

class SearchHistoryViewController: BaseViewController {

    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var searchHistoryTableView: UITableView!
    var searchHistoryArray: [String]? {
        didSet {
            guard clearButton != nil else { return }
            clearButton.isEnabled = !(searchHistoryArray?.isEmpty ?? true)
            let titleColor = UIColor(red: 0.255866, green: 0.255873, blue: 0.255869, alpha: 1)
            let buttonColor: UIColor = clearButton.isEnabled ? titleColor : .gray
            clearButton.setTitleColor(buttonColor, for: .normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.addNavigationView()
        self.navigationView?.titleLabel.text = "Search History"
        clearButton.isEnabled = false
        view.bringSubviewToFront(clearButton)
        
        let userDefaults = UserDefaults.standard
        if let history = userDefaults.object(forKey: ItemsSearchHistory) as? [String] {
            searchHistoryArray = history
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func clearHistory(_ sender: Any) {
        let popupVC = PopupViewController()
        let responder = popupVC.showAlert(viewcontroller: self, title: "Wasel Delivery", text: "Are you sure you want to clear search history?", buttonText: "Cancel", cancelButtonText: "Clear")
        responder.addCancelAction({
            DispatchQueue.main.async(execute: {
                let userDefaults = UserDefaults.standard
                self.searchHistoryArray = []
                userDefaults.set(self.searchHistoryArray, forKey: ItemsSearchHistory)
                userDefaults.synchronize()
                self.searchHistoryTableView.reloadData()
            })
        })
    }
}

extension SearchHistoryViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchHistoryArray?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SearchHistoryCell.cellIdentifier()) as? SearchHistoryCell else {
            return UITableViewCell()
        }
        cell.delegate = self
        cell.tag = indexPath.row
        if let str = searchHistoryArray?[indexPath.row] {
            cell.configureCell(with: str)
        }
        return cell
    }
}

extension SearchHistoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
}

extension SearchHistoryViewController: SearchHistoryCellDelegate {
    func searchHistoryCell(cell: SearchHistoryCell, didSelectClearHistory historyItem: String) {
        let userDefaults = UserDefaults.standard
        searchHistoryArray?.remove(at: cell.tag)
        userDefaults.set(searchHistoryArray, forKey: ItemsSearchHistory)
        userDefaults.synchronize()
        searchHistoryTableView.reloadData()
    }
    
    func reloadSearch(cell: SearchHistoryCell, didSelectClearHistory historyItem: String) {
//        let searchVC = navigationController?.viewControllers[0] as? SearchViewController
//        if let searchVC_ = searchVC {
//            searchVC_.searchField.becomeFirstResponder()
//            searchVC_.searchField.text = historyItem
//            searchVC_.textFieldValueChanged(searchVC_.searchField)
//            _ = navigationController?.popToViewController(searchVC_, animated: true)
//        }
    }
}

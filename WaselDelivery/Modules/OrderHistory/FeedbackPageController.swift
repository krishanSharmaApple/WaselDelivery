//
//  FeedbackPageController.swift
//  WaselDelivery
//
//  Created by sunanda on 1/3/17.
//  Copyright © 2017 [x]cube Labs. All rights reserved.
//

import UIKit

class FeedbackPageController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, PageViewProtocol, ReloadPageController, UIScrollViewDelegate {
    
    func reloadAmenities(list: [Amenity]?) {
        
    }

    var feedbackOrders: [Order]! {
        didSet {
            if feedbackOrders.count > 0 {
                customPageControl.numberOfPages = feedbackOrders.count
                view.bringSubviewToFront(customPageControl)
                self.setViewControllers([getViewControllerAtIndex(0)] as [UIViewController], direction: .forward, animated: false, completion: nil)
            } else if feedbackOrders.count == 0 {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    private lazy var customPageControl: UIPageControl = {
        var pageC = UIPageControl(frame: CGRect(x: 0.0, y: ScreenHeight - 30.0, width: ScreenWidth, height: 30.0))
        pageC.hidesForSinglePage = true
        return pageC
    }()

    fileprivate var currentIndex: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        self.dataSource = self
        self.delegate = self
        
        for subView in self.view.subviews {
            if subView.isKind(of: UIScrollView.self) {
                if let subView_ = subView as? UIScrollView {
                    subView_.delegate = self
                }
            }
        }
        self.view.backgroundColor = .themeColor()
        self.view.addSubview(customPageControl)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Utilities.removeTransparentView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.bringSubviewToFront(customPageControl)
        Utilities.removeTransparentView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        Utilities.log("FeedbackPage deinit" as AnyObject, type: .trace)
    }

    fileprivate func getViewControllerAtIndex(_ index: NSInteger) -> UIViewController {
        guard let pageContentViewController = self.storyboard?.instantiateViewController(withIdentifier: "FeedbackController") as? FeedbackController else {
            return UIViewController()
        }
        pageContentViewController.delegate = self
        pageContentViewController.reloadDelegate = self
        pageContentViewController.order = feedbackOrders[index]
        pageContentViewController.pageIndex = index
        return pageContentViewController
    }
    
// MARK: - UIPageViewController Delegate & DataSource
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let pageContent: FeedbackController = viewController as? FeedbackController else {
            return UIViewController()
        }
        var index = pageContent.pageIndex
        if index == 0 {
            return nil
        }
        
        index -= 1
        return getViewControllerAtIndex(index)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard let pageContent: FeedbackController = viewController as? FeedbackController else {
            return UIViewController()
        }
        var index = pageContent.pageIndex
        
        index += 1
        if index == feedbackOrders?.count ?? 0 {
            return nil
        }
        return getViewControllerAtIndex(index)
    }

    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        if feedbackOrders?.count ?? 0 == 1 {
            return 0
        }
        return feedbackOrders?.count ?? 0
    }
    
// MARK: - Delegates
    
    func updateCurrentIndex(_ index: Int) {
        currentIndex = index
        customPageControl.currentPage = currentIndex
    }

    func updateCurrentPage(_ index: Int) {
    }

    func reloadPageController(orderIndex: Int) {
        
        if feedbackOrders.count == 1 {
            if let navController = navigationController {
                navController.dismiss(animated: true, completion: nil)
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        } else {
            feedbackOrders.removeFirst()
        }
    }
    
}

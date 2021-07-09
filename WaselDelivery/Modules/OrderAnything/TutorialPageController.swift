//
//  TutorialPageController.swift
//  WaselDelivery
//
//  Created by Purpletalk on 03/27/18.
//  Copyright © 2018 [x]cube Labs. All rights reserved.
//

import UIKit

class TutorialPageController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, PageViewProtocol {
    
    private lazy var customPageControl: UIPageControl = {
        var pageC = UIPageControl(frame: CGRect(x: 0.0, y: ScreenHeight - 60.0, width: ScreenWidth, height: 30.0))
        pageC.hidesForSinglePage = true
        pageC.addTarget(self, action: #selector(self.pageChanged), for: .valueChanged)
        return pageC
    }()

    fileprivate var currentIndex: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        self.dataSource = self
        self.delegate = self
        
        self.view.backgroundColor = .white
        self.view.addSubview(customPageControl)
        customPageControl.numberOfPages = TutorialInfo.count
        customPageControl.backgroundColor = UIColor.clear
        customPageControl.pageIndicatorTintColor = UIColor(red: (217.0/255.0), green: (217.0/255.0), blue: (217.0/255.0), alpha: 1.0)
        customPageControl.currentPageIndicatorTintColor = UIColor(red: (74.0/255.0), green: (74.0/255.0), blue: (74.0/255.0), alpha: 1.0)
        view.bringSubviewToFront(customPageControl)
        
        self.setViewControllers([getViewControllerAtIndex(0)] as [UIViewController], direction: .forward, animated: false, completion: nil)
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
        Utilities.log("TutorialPageController deinit" as AnyObject, type: .trace)
    }

    fileprivate func getViewControllerAtIndex(_ index: NSInteger) -> UIViewController {
        let tutorialController = TutorialController.instantiateFromStoryBoard(.main)
        tutorialController.pageIndex = index
        tutorialController.delegate = self
        return tutorialController
    }
    
// MARK: - UIPageViewController Delegate & DataSource
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let pageContent: TutorialController = viewController as? TutorialController else {
            return nil
        }
        var index = pageContent.pageIndex
        if index == 0 {
            return nil
        }
        
        index -= 1
        return getViewControllerAtIndex(index)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard let pageContent: TutorialController = viewController as? TutorialController else {
            return nil
        }
        var index = pageContent.pageIndex
        
        index += 1
        if index == TutorialInfo.count {
            return nil
        }
        return getViewControllerAtIndex(index)
    }

    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return TutorialInfo.count
    }

    @objc func pageChanged() {
        let pageNumber = customPageControl.currentPage
        self.updateCurrentIndex(pageNumber)
    }

// MARK: - Delegates
    
    func updateCurrentIndex(_ index: Int) {
        currentIndex = index
        customPageControl.currentPage = currentIndex
    }
    
    func reloadAmenities(list: [Amenity]?) {
        
    }
    
    func updateCurrentPage(_ index: Int) {
    }

}

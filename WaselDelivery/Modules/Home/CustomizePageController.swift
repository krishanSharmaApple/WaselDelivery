//
//  CustomizePageController.swift
//  WaselDelivery
//
//  Created by sunanda on 11/25/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

class CustomizePageController: UIPageViewController {

    fileprivate var lastOffsetX: CGFloat = 0.0
    fileprivate var isNextHighLighted = false
    fileprivate var isPreviousHighLighted = false
    var currentIndex: NSInteger = 0
    var menuIndex = 0
    var viewControllersCount: NSInteger = 0
    var categories: [CustomizeCategory]?
    
    weak var pageControlDelegate: PageControllerProtocol?

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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        Utilities.log("ItemsPage deinit" as AnyObject, type: .trace)
    }
    
// MARK: - Delegate Methods
    
    func loadPageController(_ categories_: [CustomizeCategory]) {
        
        if categories_.count > 0 {
            categories = categories_
            viewControllersCount = categories?.count ?? 0
            self.setViewControllers([getViewControllerAtIndex(0)] as [UIViewController], direction: UIPageViewController.NavigationDirection.forward, animated: true, completion: nil)
            
        } else if categories_.count == 0 {
            categories = nil
            viewControllersCount = 1
            self.setViewControllers([UIViewController()] as [UIViewController], direction: UIPageViewController.NavigationDirection.forward, animated: true, completion: nil)
        }
    }
    
    func updateCurrentPage(_ index: Int) {
        
        var direction: UIPageViewController.NavigationDirection = .forward
        if currentIndex > index {
            direction = .reverse
        }
        currentIndex = index
        let currentviewController = getViewControllerAtIndex(index)
        self.setViewControllers([currentviewController], direction: direction, animated: true, completion: nil)
    }
    
// MARK: - Support Methods
    
    fileprivate func getViewControllerAtIndex(_ index: NSInteger) -> CustomizeItemController {
        
        guard let pageContentViewController = self.storyboard?.instantiateViewController(withIdentifier: "CustomizeItemController") as? CustomizeItemController else {
            return CustomizeItemController()
        }
        pageContentViewController.category = categories?[index]
        pageContentViewController.pageIndex = index
        pageContentViewController.delegate = self
        return pageContentViewController
    }
    
// MARK: - Notification Methods
    
    func updateCurrentView(_ index: Int) {
        
        var direction: UIPageViewController.NavigationDirection = .forward
        if currentIndex > index {
            direction = .reverse
        }
        currentIndex = index
        let currentviewController = getViewControllerAtIndex(index)
        self.setViewControllers([currentviewController], direction: direction, animated: true, completion: nil)
    }
}

extension CustomizePageController: UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIScrollViewDelegate, PageViewProtocol {
    
    func reloadAmenities(list: [Amenity]?) { }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        if let categories_ = categories, categories_.count > 0 {
            guard let pageContent: CustomizeItemController = viewController as? CustomizeItemController else {
                return nil
            }
            var index = pageContent.pageIndex
            
            if index == 0 {
                return nil
            }
            
            index -= 1
            return getViewControllerAtIndex(index)
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        if let categories_ = categories, categories_.count > 0 {
            guard let pageContent: CustomizeItemController = viewController as? CustomizeItemController else {
                return nil
            }
            var index = pageContent.pageIndex
            index += 1
            if index == viewControllersCount {
                return nil
            }
            return getViewControllerAtIndex(index)
        }
        return nil
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let offsetX = scrollView.contentOffset.x - ScreenWidth
        if scrollView.isDragging {
            
            var middleWidth = ScreenWidth / 2
            if (offsetX > 0 && currentIndex == self.viewControllersCount - 1) || (offsetX < 0 && currentIndex == 0) {
                resetVariables()
                return
            }
            if offsetX < 0 {
                middleWidth = -ScreenWidth / 2
            }
            if offsetX > lastOffsetX {
                if offsetX < 0 && menuIndex == currentIndex {
                    resetVariables()
                    return
                }
                lastOffsetX = offsetX
                if lastOffsetX > middleWidth && isNextHighLighted == false {
                    moveToNextIndex(true)
                }
            } else if offsetX < lastOffsetX {
                if offsetX > 0 && menuIndex == currentIndex {
                    resetVariables()
                    return
                }
                lastOffsetX = offsetX
                if lastOffsetX < middleWidth && isPreviousHighLighted == false {
                    moveToNextIndex(false)
                }
            }
        }
    }
    
    fileprivate func moveToNextIndex(_ isForward: Bool) {
        isNextHighLighted = isForward
        isPreviousHighLighted = !isForward
        menuIndex = isForward ? menuIndex + 1 : menuIndex - 1
        if menuIndex < 0 || menuIndex == viewControllersCount {
            resetVariables()
            menuIndex = menuIndex < 0 ? 0 : viewControllersCount - 1
            return
        }
        pageControlDelegate?.scrollToHeaderIndex(menuIndex)
    }
    
    func resetVariables() {
        isNextHighLighted = false
        isPreviousHighLighted = false
        lastOffsetX = 0.0
    }
    
    func updateCurrentIndex(_ index: Int) {
        currentIndex = index
        menuIndex = currentIndex
        resetVariables()
        pageControlDelegate?.scrollToHeaderIndex(currentIndex)
    }
}

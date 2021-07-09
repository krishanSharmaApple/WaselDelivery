//
//  OutletItemsPageController.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 16/09/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

class OutletItemsPageController: UIPageViewController {
    
    fileprivate var lastOffsetX: CGFloat = 0.0
    fileprivate var isNextHighLighted = false
    fileprivate var isPreviousHighLighted = false
    var currentIndex: NSInteger = 0
    var menuIndex = 0
    var viewControllersCount: NSInteger = 0
    var outletItemsArray: [OutletItemCategory]?

    weak var pageControlDelegate: PageControllerProtocol?
    
// MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dataSource = self
        self.delegate = self
        self.setViewControllers([getViewControllerAtIndex(0)] as [UIViewController], direction: UIPageViewControllerNavigationDirection.forward, animated: false, completion: nil)
        
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
        debugPrint("ItemsPage deinit")
    }
    
// MARK: - Support Methods

    fileprivate func getViewControllerAtIndex(_ index: NSInteger) -> OutletItemsController {
        
        guard let pageContentViewController = self.storyboard?.instantiateViewController(withIdentifier: "OutletItemsController") as? OutletItemsController else {
            return UIViewController()
        }
        if let itemIndex = outletItemsArray?[index] {
            pageContentViewController.foodItemCategory = itemIndex
        }
//        pageContentViewController.pageIndex = index
//        pageContentViewController.delegate = self
        return pageContentViewController
    }
    
// MARK: - Notification Methods
    
    func updateCurrentView(_ index: Int) {
        
        var direction: UIPageViewControllerNavigationDirection = .forward
        if currentIndex > index {
            direction = .reverse
        }
        currentIndex = index
        let currentviewController = getViewControllerAtIndex(index)
        self.setViewControllers([currentviewController], direction: direction, animated: true, completion: nil)
    }
}

extension OutletItemsPageController: UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIScrollViewDelegate, PageViewProtocol {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let pageContent: OutletItemsController = viewController as? OutletItemsController else {
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
        
        guard let pageContent: OutletItemsController = viewController as? OutletItemsController else {
            return UIViewController()
        }
        var index = pageContent.pageIndex
        index += 1
        if index == viewControllersCount {
            return nil
        }
        return getViewControllerAtIndex(index)
    }
    
// MARK: - UIScrollViewDelegate
    
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

//
//  HomePageController.swift
//  WaselDelivery
//
//  Created by sunanda on 11/4/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

class HomePageController: UIPageViewController {
    
    fileprivate var lastOffsetX: CGFloat = 0.0
    fileprivate var isNextHighLighted = false
    fileprivate var isPreviousHighLighted = false
    fileprivate var amenityTitles: [Amenity]? {
        didSet {
            if let parent_ = parent as? HomeViewController {
                parent_.homeHeader.titles = amenityTitles
            }
        }
    }
    fileprivate var currentIndex: NSInteger = 0
    var menuIndex = 0
    var viewControllersCount: NSInteger = 0
    weak var homeDelegate: PageControllerProtocol?

    // MARK: - View Life Cycle
    
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

    deinit {
        Utilities.log("HomePage deinit" as AnyObject, type: .trace)
    }
    
// MARK: - Delegate Methods
    
    func loadPageController(_ titles: [Amenity]) {
        if titles.count > 0 {
            amenityTitles = titles
            if let amenityArray = amenityTitles {
                viewControllersCount = amenityArray.count
            } else {
                viewControllersCount = 0
            }
//            viewControllersCount = amenityTitles!.count
            self.setViewControllers([getViewControllerAtIndex(0)] as [UIViewController], direction: UIPageViewController.NavigationDirection.forward, animated: false, completion: nil)
        } else if titles.count == 0 {
            amenityTitles = nil
            viewControllersCount = 1
            self.setViewControllers([UIViewController()] as [UIViewController], direction: UIPageViewController.NavigationDirection.forward, animated: false, completion: nil)
        }
    }
    
    func updateCurrentPage(_ index: Int) {
        
        if amenityTitles != nil {
            var direction: UIPageViewController.NavigationDirection = .forward
            if currentIndex > index {
                direction = .reverse
            }
            currentIndex = index
            let currentviewController = getViewControllerAtIndex(index)
            self.setViewControllers([currentviewController], direction: direction, animated: false, completion: nil)
        }
    }
    
// MARK: - Support Methods
    
    fileprivate func getViewControllerAtIndex(_ index: NSInteger) -> UIViewController {
        
        guard let pageContentViewController = self.storyboard?.instantiateViewController(withIdentifier: "HomeOutletController") as? HomeOutletController else {
            return UIViewController()
        }
        pageContentViewController.delegate = self
        pageContentViewController.pushDelegate = self
        pageContentViewController.controllerIndex = index
        if let amenityTitles_ = amenityTitles {
            pageContentViewController.amenity = amenityTitles_[index]
        }
        return pageContentViewController
    }
}

extension HomePageController: UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIScrollViewDelegate, PageViewProtocol, PageViewDelegte {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        if let titles_ = amenityTitles, titles_.count > 0 {
            guard let pageContent: HomeOutletController = viewController as? HomeOutletController else {
                return nil
            }
            var index = pageContent.controllerIndex
            if index == 0 {
                return nil
            }
            
            index -= 1
            return getViewControllerAtIndex(index)

        } else {
            return nil
        }
        
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        if let titles_ = amenityTitles, titles_.count > 0 {
            guard let pageContent: HomeOutletController = viewController as? HomeOutletController else {
                return nil
            }
            var index = pageContent.controllerIndex
            
            index += 1
            if index == viewControllersCount {
                return nil
            }
            return getViewControllerAtIndex(index)
        } else {
            return nil
        }
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
    
    func moveToNextIndex(_ isForward: Bool) {
        isNextHighLighted = isForward
        isPreviousHighLighted = !isForward
        menuIndex = isForward ? menuIndex + 1 : menuIndex - 1
        if menuIndex < 0 || menuIndex == viewControllersCount {
            resetVariables()
            menuIndex = menuIndex < 0 ? 0 : viewControllersCount - 1
            return
        }
        homeDelegate?.scrollToHeaderIndex(menuIndex)
    }
    
    func resetVariables() {
        isNextHighLighted = false
        isPreviousHighLighted = false
        lastOffsetX = 0.0
    }
    
// MARK: - PageViewProtocol -
    
    func updateCurrentIndex(_ index: Int) {
        currentIndex = index
        menuIndex = currentIndex
        resetVariables()
        homeDelegate?.scrollToHeaderIndex(currentIndex)
    }
    
    func reloadAmenities(list: [Amenity]?) {
        self.amenityTitles = list
        if let _list = list {
            self.loadPageController(_list)
        } else {
            self.loadPageController([Amenity]())
        }
    }
    
// MARK: - PageViewDelegte - 
    
    func pushToDetailsController(_ outlet_: Outlet, outletsInfo_: OutletsInfo) {

        let storyBoard = Utilities.getStoryBoard(forName: .main)
        if let controller = storyBoard.instantiateViewController(withIdentifier: "OutletDetailsViewController") as? OutletDetailsViewController {
            controller.outlet = outlet_
            controller.selectedOutletInformation = outletsInfo_
            controller.loadRestaurantDetails { (isRestaurantDetailsFetched, _) in
                if true == isRestaurantDetailsFetched {
                    controller.isFromSearchScreen = false
                    self.navigationController?.pushViewController(controller, animated: true)
                }
            }
        }
    }
}

//
//  Protocols.swift
//  WaselDelivery
//
//  Created by sunanda on 11/21/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import Foundation

protocol PageControllerProtocol: class {
    func scrollToHeaderIndex(_ atIndex: Int)
}

protocol HeaderProtocol: class {
    func scrollToViewController(_ atIndex: Int)
}

protocol PageViewProtocol: class {
    func updateCurrentIndex(_ index: Int)
    func reloadAmenities(list: [Amenity]?)
    func updateCurrentPage(_ index: Int)
}

protocol Copyable {
    init(instance: Self)
}

extension Copyable {
    func copy() -> Self {
        return Self.init(instance: self)
    }
}

protocol ReloadDelegate: class {
    func reloadData()
}

protocol Controller: class { }

extension Controller {
    
    static func getInstanceFrom(storyBoard: StoryBoard) -> Self? {
        let storyBoard = Utilities.getStoryBoard(forName: storyBoard)
        guard let waselVC = storyBoard.instantiateViewController(withIdentifier: String(describing: Self.self)) as? Self else {
            return nil
        }
        return waselVC
    }
    
}

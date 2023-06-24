//
//  AutoCarouselViewDelegate.swift
//  FreeDesign
//
//  Created by feng qiu on 2023/6/23.
//

import UIKit

public protocol AutoCarouselViewDelegate: AnyObject {
    func numberOfCells() -> Int
    func carouselView(_ carouselView: AutoCarouselView, cellForIndex index: Int) -> UIView?
    func carouselView(_ carouselView: AutoCarouselView, didSelectCell cell: UIView?, atIndex index: Int)
}

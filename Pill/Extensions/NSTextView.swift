//
//  NSTextView.swift
//  Pill
//
//  Created by Chris Zielinski on 8/26/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Cocoa

extension NSTextView {
    /// Converts a point from the coordinate system of the text view to that of the text container view.
    ///
    /// - Parameter point: A point specifying a location in the coordinate system of text view.
    /// - Returns: The point converted to the coordinate system of the text view's text container.
    func convertToTextContainer(_ point: NSPoint) -> NSPoint {
        return NSPoint(x: point.x - textContainerOrigin.x, y: point.y - textContainerOrigin.y)
    }
}

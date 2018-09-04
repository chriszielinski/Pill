//
//  NSAttributedString.swift
//  Pill
//
//  Created by Chris Zielinski on 8/24/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Cocoa

public extension NSAttributedString {
    /// Returns the character range of the entire string.
    /// 
    var contentRange: NSRange {
        return NSRange(location: 0, length: length)
    }
}

public extension NSMutableAttributedString {
    /// Adds the given collection of attributes to all the characters.
    /// 
    /// - Parameter attributes: A dictionary containing the attributes to add.
    func addAttributes(_ attributes: [NSAttributedStringKey : Any]) {
        addAttributes(attributes, range: contentRange)
    }

    /// Adds an attribute with the given name and value to all the characters.
    /// 
    /// - Parameters: 
    ///     - name: A attribute key specifying the attribute name.
    ///     - value: The attribute value associated with name.
    func addAttribute(_ name: NSAttributedStringKey, value: Any) {
        addAttribute(name, value: value, range: contentRange)
    }

    /// Removes the named attribute from all the characters.
    /// 
    /// - Parameter name: The attribute name to remove.
    func removeAttribute(_ name: NSAttributedStringKey) {
        removeAttribute(name, range: contentRange)
    }
}

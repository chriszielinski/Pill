//
//  PillStringWrapper.swift
//  Pill
//
//  Created by Chris Zielinski on 8/29/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Cocoa

/// A wrapper that contains both the original string and its pillified attributed string.
public struct PillStringWrapper {
    /// Returns the original string used to initialize the receiver, prior to it being parsed for pills.
    public let originalString: String
    /// Returns the attributed string containing pills parsed from the string used to initialize this instance (`originalString`).
    public let attributedString: NSAttributedString

    /// Creates a new pill string wrapper. The given `string` will be parsed for pills using the `shared` pill data detector.
    ///
    /// - Parameter string: The string, optionally, containing plaintext pills that will be parsed and replaced.
    public init(string: String) {
        originalString = string
        attributedString = NSAttributedString(attributedString: PillDataDetector.shared.pillify(string: string))
    }
}

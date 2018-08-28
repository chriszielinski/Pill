//
//  PillDataDetector.swift
//  Pill
//
//  Created by Chris Zielinski on 8/27/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Cocoa

open class PillDataDetector: NSRegularExpression {

    /// The application's shared pill data detector initialized with the `pillRegex` pattern.
    public static var shared: PillDataDetector = PillDataDetector()
    /// The regular expression pattern used by the shared pill data detector.
    public static var pillRegex: String = "<(.*?)>"

    override public init(pattern: String, options: NSRegularExpression.Options = []) throws {
        try super.init(pattern: pattern, options: options)
    }

    convenience public init() {
        try! self.init(pattern: PillDataDetector.pillRegex)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Parse and replace plaintext pills in a string using the `shared` pill data detector.
    ///
    /// - Parameter string: The string to parse pills out of.
    /// - Returns: Returns a mutable attributed string containing `Pill`s and any remaining original text.
    public static func pillify(string: String) -> NSMutableAttributedString {
        return shared.pillify(string: string)
    }

    /// Parse and replace plaintext pills in a string.
    ///
    /// - Parameter string: The string to parse pills out of.
    /// - Returns: Returns a mutable attributed string containing `Pill`s and any remaining original text.
    public func pillify(string: String) -> NSMutableAttributedString {
        var pills: [(NSRange, Pill)] = []
        let nsString = string as NSString
        var mutableAttributedString = NSMutableAttributedString(string: string)

        func replace(_ result: NSTextCheckingResult?, _ flags: NSRegularExpression.MatchingFlags, _ shouldStop: UnsafeMutablePointer<ObjCBool>) {
            // Result guaranteed to be non-nil.
            pills.append((result!.range,
                           Pill(with: nsString.substring(with: result!.range(at: 1)))))
        }

        enumerateMatches(in: string,
                         range: mutableAttributedString.contentRange,
                         using: replace)
        pills.reversed().forEach {
            mutableAttributedString.replaceCharacters(in: $0.0, with: $0.1.attributedStringValue)
        }

        return mutableAttributedString
    }
}

//
//  PillDataDetector.swift
//  Pill
//
//  Created by Chris Zielinski on 8/27/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Cocoa

open class PillDataDetector: NSRegularExpression {

    public static var pillRegex: String = "<(.*?)>"

    override public init(pattern: String, options: NSRegularExpression.Options = []) throws {
        try super.init(pattern: pattern, options: options)
    }

    convenience public init() {
        try! self.init(pattern: PillDataDetector.pillRegex)
    }

    @discardableResult
    convenience public init(mutableAttributedString: NSMutableAttributedString) {
        self.init()
        pillify(mutableAttributedString: mutableAttributedString)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func pillify(mutableAttributedString: NSMutableAttributedString) {
        var pills: [(NSRange, Pill)] = []
        let nsString = mutableAttributedString.string as NSString

        func replace(_ result: NSTextCheckingResult?, _ flags: NSRegularExpression.MatchingFlags, _ shouldStop: UnsafeMutablePointer<ObjCBool>) {
            // Result guaranteed to be non-nil.
            pills.append((result!.range,
                           Pill(with: nsString.substring(with: result!.range(at: 1)))))
        }

        enumerateMatches(in: mutableAttributedString.string,
                         range: mutableAttributedString.contentRange,
                         using: replace)
        pills.reversed().forEach {
            mutableAttributedString.replaceCharacters(in: $0.0, with: $0.1.attributedStringValue)
        }
    }
}

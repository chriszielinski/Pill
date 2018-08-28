//
//  ViewController.swift
//  Pill
//
//  Created by Chris Zielinski on 8/20/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Cocoa
import Pill

class ViewController: NSViewController {

    @IBOutlet var pillTextView: PillTextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the pill content text font.
        Pill.sharedFont = pillTextView.font!
        // Add an inset to the text container.
        pillTextView.textContainerInset = NSSize(width: 5, height: 5)

        // Create the mutable attributed string containing the pills.
        let mutableAttributedString = NSMutableAttributedString(string: "Hey <Xcode>, check out my <pills💊>!")
        // Parses the mutable attributed string's pills and sets the result to the text view.
        pillTextView.pillTextStorage.pillifyAndSetAttributedString(mutableAttributedString)

        // Add some paragraph formatting.
        let mutableParagraphStyle = NSMutableParagraphStyle()
        let lineHeight: CGFloat = 20
        mutableParagraphStyle.minimumLineHeight = lineHeight
        mutableParagraphStyle.maximumLineHeight = lineHeight
        mutableParagraphStyle.lineSpacing = 2
        pillTextView.defaultParagraphStyle = mutableParagraphStyle

        // Raise the baseline to vertically center the pill.
        pillTextView.pillTextStorage.addAttribute(.baselineOffset, value: 2)
        // Add the raised baseline attribute to the typing attributes to maintain it in subsequent typing.
        pillTextView.typingAttributes[.baselineOffset] = 2
    }

}

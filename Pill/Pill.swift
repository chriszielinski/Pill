//
//  Pill.swift
//  Pill
//
//  Created by Chris Zielinski on 8/20/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Cocoa

open class Pill: NSTextAttachment {

    /// A type of interaction the user performed on a selected pill.
    ///
    /// - delete: The user pressed the delete key.
    /// - enter: The user pressed the enter key.
    /// - doubleClick: The user double clicked.
    public enum UserInteraction {
        /// The user pressed the delete key while focused on a pill.
        case delete
        /// The user pressed the enter key while focused on a pill.
        case enter
        /// The user double clicked on a pill.
        case doubleClick
    }

    /// A type of replacement action the pill should perform.
    ///
    /// - delete: Replace the selected pill with an empty string.
    /// - insert: Replace the selected pill with the text contents of the pill.
    /// - ignore: Do nothing.
    public enum ReplacementAction {
        /// Replace the selected pill with an empty string.
        case delete
        /// Replace the selected pill with the text contents of the pill.
        case insert
        /// Do nothing.
        case ignore
    }

    /// The font that all pills use to display text.
    public static var sharedFont: NSFont = NSFont.systemFont(ofSize: NSFont.systemFontSize)
    /// The radius to use when drawing rounded corners for the pill. By default, a radius of 1/5 the pill height is used.
    public static var cornerRadius: CGFloat?
    /// The inner padding added between each pill side and its text content.
    public static var textWidthPadding: CGFloat = 7

    public var pillAttachmentCell: PillTextAttachmentCell {
        return attachmentCell as! PillTextAttachmentCell
    }

    /// The color used to draw the pill's text.
    open var textColor: NSColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    /// The color used to draw the pill background.
    open var backgroundColor: NSColor = #colorLiteral(red: 0.7333333333, green: 0.7333333333, blue: 0.7333333333, alpha: 1)
    /// The color used to draw the pill background when selected (highlighted).
    open var highlightColor: NSColor = #colorLiteral(red: 0.08235294118, green: 0.4941176471, blue: 0.9843137255, alpha: 1)
    /// The color used to draw the pill border.
    ///
    /// - Note: When nil, no border is drawn.
    ///
    open var borderColor: NSColor?
    /// The width of the pill border.
    ///
    /// - Note: Border is not drawn if `borderColor` is nil.
    ///
    open var borderWidth: CGFloat = 1

    /// The attributed string containing the pill as an attachment.
    public var attributedStringValue: NSAttributedString {
        return NSAttributedString(attachment: self)
    }
    /// Returns the text content of the pill.
    open var contentStringValue: String {
        return pillAttachmentCell.drawnAttributedString.string
    }
    /// Returns whether the pill is currently selected.
    open var isSelected: Bool {
        return pillAttachmentCell.isHighlighted
    }

    public init(with string: String) {
        super.init(data: nil, ofType: nil)

        attachmentCell = PillTextAttachmentCell(textCell: string)
        contents = string.data(using: .utf8)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Attribute Methods

extension Pill {
    /// Adds an attribute with the given name and value to the pill text.
    func addAttribute(_ name: NSAttributedStringKey, value: Any) {
        pillAttachmentCell.drawnAttributedString.addAttribute(name, value: value)
    }

    /// Removes the named attribute from the pill text.
    func removeAttribute(_ name: NSAttributedStringKey) {
        pillAttachmentCell.drawnAttributedString.removeAttribute(name)
    }
}

//
//  Pill.swift
//  Pill
//
//  Created by Chris Zielinski on 8/21/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Cocoa

open class PillTextView: NSTextView {

    /// The pill text view's delegate.
    ///
    /// The default behavior of pill replacement is as so:
    /// - The enter key inserts the pill's text content.
    /// - Double clicking and pressing the delete key, deletes the pill.
    public weak var pillTextViewDelegate: PillTextViewDelegate! {
        didSet {
            // Can never be nil.
            if pillTextViewDelegate == nil {
                pillTextViewDelegate = self
            }
        }
    }
    /// The currently selected (focused) pill in the text view.
    open weak var selectedPill: Pill?

    public var pillTextStorage: PillTextStorage = PillTextStorage()
    public var pillLayoutManager: PillLayoutManager = PillLayoutManager()

    /// Whether there is a pill that is currently selected (focused).
    public var hasSelectedPill: Bool {
        return selectedPill != nil
    }
    /// Whether the text view has any visible pills.
    public var hasPills: Bool {
        return pillTextStorage.hasPills
    }

    override public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    override public init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
        super.init(frame: frameRect, textContainer: container)
        commonInit()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override open func awakeFromNib() {
        super.awakeFromNib()
        commonInit()
    }

    open func commonInit() {
        textContainer!.replaceLayoutManager(pillLayoutManager)
        layoutManager!.replaceTextStorage(pillTextStorage)
        pillTextViewDelegate = self
    }
}

// MARK: - Pill Query Methods

extension PillTextView {
    /// Returns the pill falling under the given point, expressed in the text view's coordinate system.
    ///
    /// - Parameter point: The point for which to return the pill, in coordinates of the text view.
    /// - Returns: The pill falling under the given point, expressed in the text view's coordinate system.
    internal func pill(at point: NSPoint) -> Pill? {
        let pointInTextContainer = convertToTextContainer(point)
        guard let characterIndex = pillLayoutManager.characterIndex(for: pointInTextContainer,
                                                                     in: textContainer!)
            else { return nil }
        return pillTextStorage.pill(at: characterIndex)
    }
}

// MARK: - Pill Selection Methods

extension PillTextView {
    /// Calls the necessary methods to redraw the specified pill as highlighted or unhighlighted.
    ///
    /// - Parameters:
    ///   - pill: The pill that will be redrawn.
    ///   - flag: When `true`, redraws the pill as highlighted; otherwise, redraws it normally.
    private func highlight(_ pill: Pill, flag: Bool) {
        if let characterRange = pillTextStorage.characterRange(of: pill) {
            pill.pillAttachmentCell.highlight(flag, withFrame: pill.bounds, in: self)
            pillLayoutManager.invalidateDisplay(forCharacterRange: characterRange)
        }
    }

    /// Selects the given pill, deselecting a currently selected one. Redrawing involved pills with appropriate highlighting.
    ///
    /// - Parameter pill: The pill to select.
    public func selectPill(_ pill: Pill) {
        guard pill != selectedPill
            else { return }

        deselectSelectedPill()
        highlight(pill, flag: true)
        selectedPill = pill

        if let characterIndex = pillTextStorage.characterIndex(of: pill) {
            setSelectedRange(NSRange(location: characterIndex, length: 1))
        }
    }

    /// Deselects the currently select pill, if there is one.
    public func deselectSelectedPill() {
        if let selectedPill = selectedPill {
            highlight(selectedPill, flag: false)
            self.selectedPill = nil
        }
    }
}

// MARK: - Pill Interaction Methods

extension PillTextView {
    /// Handles the user's interaction with a pill by querying the replacement action from the pill view's delegate and invoking the respective replacement methods.
    ///
    /// - Parameters:
    ///   - interaction: The type of interaction to handle.
    ///   - pill: The pill to replace.
    internal func handlePillInteraction(_ interaction: Pill.UserInteraction, for pill: Pill) {
        let replacementAction = pillTextViewDelegate.pillTextView(self, userInteraction: interaction, for: pill)
        switch replacementAction {
        case .insert:
            crushPill(pill)
        case .delete:
            swallowPill(pill)
        case .ignore: ()
        }
    }

    /// Replaces the pill with an empty string.
    ///
    /// - Parameter pill: The pill to replace.
    public func deletePill(_ pill: Pill) {
        if let characterRange = pillTextStorage.characterRange(of: pill) {
            selectedPill = nil
            shouldChangeText(in: characterRange, replacementString: "")
            pillTextStorage.deletePill(at: characterRange.location)
            didChangeText()
            setSelectedRange(NSRange(location: characterRange.location, length: 0))
        }
    }

    /// Replaces the pill with its text contents.
    ///
    /// - Parameter pill: The pill to replace.
    public func insertText(for pill: Pill) {
        if let characterRange = pillTextStorage.characterRange(of: pill) {
            selectedPill = nil
            shouldChangeText(in: characterRange, replacementString: pill.contentStringValue)
            pillTextStorage.replaceCharacters(in: characterRange, with: pill.contentStringValue)
            didChangeText()
        }
    }

    /// Replaces the pill with an empty string.
    ///
    /// - Parameter pill: The pill to replace.
    private func swallowPill(_ pill: Pill) {
        deletePill(pill)
    }

    /// Replaces the pill with its text contents.
    ///
    /// - Parameter pill: The pill to open.
    private func crushPill(_ pill: Pill) {
        insertText(for: pill)
    }
}

// MARK: - Overridden Properties

extension PillTextView {
    override open var defaultParagraphStyle: NSParagraphStyle? {
        get { return super.defaultParagraphStyle }
        set {
            super.defaultParagraphStyle = newValue
            if let paragraphStyle = defaultParagraphStyle {
                pillTextStorage.addAttribute(.paragraphStyle, value: paragraphStyle)
            }
        }
    }

    override open var typingAttributes: [NSAttributedStringKey: Any] {
        get { return super.typingAttributes }
        set {
            // Never want to type in the AppleColorEmoji font. 🚮
            guard (newValue[.font] as? NSFont)?.fontName != "AppleColorEmoji"
                else { return }
            super.typingAttributes = newValue
        }
    }
}

// MARK: - Overridden Methods

extension PillTextView {
    override open func changeFont(_ sender: Any?) {
        super.changeFont(sender)
        Pill.sharedFont = NSFontManager.shared.convert(Pill.sharedFont)
        pillLayoutManager.invalidateAllPills()
    }

    override open func writeSelection(to pboard: NSPasteboard, type: NSPasteboard.PasteboardType) -> Bool {
        let writeRange = selectedRange()

        if pillTextStorage.containsAttachments(in: writeRange) {
            // Currently only support copying plain text.
            let mutableString = NSMutableAttributedString(attributedString: pillTextStorage.attributedSubstring(from: writeRange))

            mutableString.enumerateAttribute(.attachment, in: mutableString.contentRange, options: .longestEffectiveRangeNotRequired) { (attachment, range, _) in
                guard let pill = attachment as? Pill else { return }
                mutableString.replaceCharacters(in: range, with: pill.contentStringValue)
            }

            pboard.clearContents()
            pboard.writeObjects([mutableString.mutableString])
            return true
        } else {
            return super.writeSelection(to: pboard, type: type)
        }
    }
}

// MARK: - Text Selection Methods

extension PillTextView {
    override open func setSelectedRange(_ charRange: NSRange, affinity: NSSelectionAffinity, stillSelecting stillSelectingFlag: Bool) {
        // If selection is a pill, select it. This is meant for a drag selection.
        if let selectionPill = pillTextStorage.pill(at: charRange) {
            selectPill(selectionPill)
        } else {
            // Otherwise, deselect any currently selected pill.
            deselectSelectedPill()
        }

        super.setSelectedRange(charRange, affinity: affinity, stillSelecting: stillSelectingFlag)
    }
}

// MARK: - Responder Methods

extension PillTextView {
    override open func mouseDown(with event: NSEvent) {
        guard let pill = pill(at: convert(event.locationInWindow, from: nil)) else {
            // Click was not on a pill, so deselect any select pill and call super.
            deselectSelectedPill()
            return super.mouseDown(with: event)
        }

        if pill != selectedPill {
            // Pill is not already selected, so select it.
            selectPill(pill)
        } else if event.clickCount > 1 {
            // Pill interaction was (at least) a double click, so handle it, appropriately.
            handlePillInteraction(.doubleClick, for: pill)
        }
    }

    override open func insertTab(_ sender: Any?) {
        if let selectedPill = selectedPill {
            // If there's a following pill, select it. Otherwise, do nothing.
            if let nextPill = pillTextStorage.pillFollowing(selectedPill) {
                selectPill(nextPill)
            }
        } else {
            // No currently selected pill, find closest one and select it.
            if let closestPill = pillTextStorage.closestPill(to: selectedRange().location) {
                selectPill(closestPill)
            } else {
                // Otherwise, call super.
                super.insertTab(sender)
            }
        }
    }

    override open func insertNewline(_ sender: Any?) {
        if let selectedPill = selectedPill {
            handlePillInteraction(.enter, for: selectedPill)
        } else {
            super.insertNewline(sender)
        }
    }

    override open func deleteBackward(_ sender: Any?) {
        if let selectedPill = selectedPill {
            handlePillInteraction(.delete, for: selectedPill)
        } else {
            super.deleteBackward(sender)
        }
    }

    override open func moveLeft(_ sender: Any?) {
        let currentSelectedRange = selectedRange()

        if hasSelectedPill {
            // There's a selected pill, so deselect it and call super (which will move the insertion point to the left side of the pill).
            // Note: There may be a neighboring pill to the left, so need to check this case before the next one.
            deselectSelectedPill()
        } else if currentSelectedRange.length == 0,
            let pill = pillTextStorage.pill(at: currentSelectedRange.location - 1) {
            // No current selection and previous character index is a pill, so just select it.
            return selectPill(pill)
        } else {
            // Otherwise, deselect a selected pill, if there is one.
            deselectSelectedPill()
        }

        super.moveLeft(sender)
    }

    override open func moveRight(_ sender: Any?) {
        let currentSelectedRange = selectedRange()

        if hasSelectedPill {
            // There's a selected pill, so deselect it and call super (which will move the insertion point to the right side of the pill).
            // Note: There may be a neighboring pill to the right, so need to check this case before the next one.
            deselectSelectedPill()
        } else if currentSelectedRange.length == 0,
            let pill = pillTextStorage.pill(at: currentSelectedRange.location) {
            // No current selection and bordering a pill, so just select it.
            return selectPill(pill)
        } else {
            // Otherwise, deselect a selected pill, if there is one.
            deselectSelectedPill()
        }

        super.moveRight(sender)
    }
}

// MARK: - Default Delegate Methods

extension PillTextView: PillTextViewDelegate {
    open func pillTextView(_ pillTextView: PillTextView, userInteraction: Pill.UserInteraction, for pill: Pill) -> Pill.ReplacementAction {
        switch userInteraction {
        case .enter:
            return .insert
        default:
            return .delete
        }
    }
}

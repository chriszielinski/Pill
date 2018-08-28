//
//  PillLayoutManager.swift
//  Pill
//
//  Created by Chris Zielinski on 8/23/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Cocoa

open class PillLayoutManager: NSLayoutManager {

    public var pillTextStorage: PillTextStorage? {
        return textStorage as? PillTextStorage
    }

    override open func fillBackgroundRectArray(_ rectArray: UnsafePointer<NSRect>, count rectCount: Int, forCharacterRange charRange: NSRange, color: NSColor) {
        guard pillTextStorage?.pill(at: charRange) == nil
            // Don't fill in selection background when only selection is a pill. Not pretty, but it works.
            else { return }
        super.fillBackgroundRectArray(rectArray, count: rectCount, forCharacterRange: charRange, color: color)
    }
}

// MARK: - Pill Query Methods

public extension PillLayoutManager {
    /// Returns the index of the character falling under the given point, expressed in the given container's coordinate system.
    ///
    /// - Parameters:
    ///   - point: The point for which to return the character index, in coordinates of `textContainer`.
    ///   - textContainer: The container in which the returned character index is laid out.
    /// - Returns: The index of the character falling under the given point, expressed in the given container's coordinate system.
    func characterIndex(for point: NSPoint, in textContainer: NSTextContainer) -> Int? {
        // Convert point to the nearest glyph index.
        let index = glyphIndex(for: point,
                               in: textContainer,
                               fractionOfDistanceThroughGlyph: nil)
        // Check to see whether the mouse actually lies over the glyph it is nearest to.
        let glyphRect = boundingRect(forGlyphRange: NSRange(location: index, length: 1),
                                     in: textContainer)
        if glyphRect.contains(point) {
            // Convert the glyph index to a character index.
            return characterIndexForGlyph(at: index)
        }
        return nil
    }
}

// MARK: - Pill Invalidation Methods

public extension PillLayoutManager {
    /// Invalidates display and layout for all pills.
    func invalidateAllPills() {
        pillTextStorage?.pills.values.forEach {
            let range = NSRange(location: $0, length: 1)
            invalidateDisplay(forCharacterRange: range)
            invalidateLayout(forCharacterRange: range, actualCharacterRange: nil)
        }
    }
}

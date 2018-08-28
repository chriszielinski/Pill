//
//  PillTextAttachmentCell.swift
//  Pill
//
//  Created by Chris Zielinski on 8/21/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Cocoa

open class PillTextAttachmentCell: NSTextAttachmentCell {

    /// The cell's backing store of a mutable attributed string. Drawn inside the pill.
    open var drawnAttributedString: NSMutableAttributedString

    private var pill: Pill {
        return attachment as! Pill
    }

    override public init(textCell string: String) {
        drawnAttributedString = NSMutableAttributedString(string: string)
        super.init(textCell: string)
    }

    required public init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Primitive Layout Methods

extension PillTextAttachmentCell {
    override open func cellSize() -> NSSize {
        updateTextAttributes()
        var size = drawnAttributedString.size()
        // Add the width padding on each side.
        size.width += 2 * Pill.textWidthPadding
        return size
    }

    override open func cellBaselineOffset() -> NSPoint {
        // For some reason... this happens to be the magic number...
        return NSPoint(x: 0, y: floor(Pill.sharedFont.descender))
    }

    override open func cellFrame(for textContainer: NSTextContainer, proposedLineFragment lineFrag: NSRect, glyphPosition position: NSPoint, characterIndex charIndex: Int) -> NSRect {
        var superFrame = super.cellFrame(for: textContainer, proposedLineFragment: lineFrag, glyphPosition: position, characterIndex: charIndex)
        // Want the entire line fragment height.
        superFrame.size.height = lineFrag.height
        return superFrame
    }
}

// MARK: - Drawing Methods

extension PillTextAttachmentCell {
    override open func draw(withFrame cellFrame: NSRect, in controlView: NSView?, characterIndex charIndex: Int, layoutManager: NSLayoutManager) {
        var pillFrame = cellFrame
        let glyphIndex = layoutManager.glyphIndexForCharacter(at: charIndex)
        // Need the line fragment height in order to maintain baseline alignment with surrounding text.
        let lineFragmentRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex,
                                                              effectiveRange: nil,
                                                              withoutAdditionalLayout: true)
        // Difference of the line fragment rect height and bounding rect height. Accounts for characters drawn outside of the line fragment (aka. emojis).
        var lineFragBoundingHeightDelta: CGFloat = 0
        if let textContainer = layoutManager.textContainer(forGlyphAt: glyphIndex, effectiveRange: nil) {
            // Should never return nil, but better safe.
            let glyphRange = NSRange(location: glyphIndex, length: 1)
            let boundingRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
            lineFragBoundingHeightDelta = boundingRect.height - lineFragmentRect.height
        }
        pillFrame.origin.y += lineFragBoundingHeightDelta

        // Draw the pill.
        let radius = Pill.cornerRadius ?? pillFrame.height / 5
        let pillPath = NSBezierPath(roundedRect: pillFrame, xRadius: radius, yRadius: radius)
        (isHighlighted ? pill.highlightColor : pill.backgroundColor).setFill()
        pillPath.fill()

        // Draw the border, if wanted.
        if let borderColor = pill.borderColor {
            borderColor.setStroke()
            pillPath.lineWidth = pill.borderWidth
            pillPath.stroke()
        }

        // Draw the text.
        let stringSize = drawnAttributedString.size()
        // The frame to draw the text in. Horizontally center within pillFrame.
        let textFrame = CGRect(x: pillFrame.origin.x + ((pillFrame.width - stringSize.width) / 2),
                               y: pillFrame.origin.y,
                               width: stringSize.width,
                               height: lineFragmentRect.height)
        // Get the baseline offset, so we can maintain alignment with surrounding text.
        let baselineOffset = layoutManager.typesetter.baselineOffset(in: layoutManager,
                                                                     glyphIndex: glyphIndex)
        // Create the lower-left origin point.
        let baselineOriginPoint = NSPoint(x: textFrame.origin.x, y: textFrame.maxY - baselineOffset)
        // Draw string on baseline. Size can be ignored because it specifies max bounds for drawing (which we do not need).
        drawnAttributedString.draw(with: NSRect(origin: baselineOriginPoint, size: .zero))
    }

    override open func highlight(_ flag: Bool, withFrame cellFrame: NSRect, in controlView: NSView?) {
        isHighlighted = flag
    }
}

// MARK: - Attribute Modification Methods

extension PillTextAttachmentCell {
    private func updateTextAttributes() {
        drawnAttributedString.addAttributes([
            .font: Pill.sharedFont,
            .foregroundColor: pill.textColor
            ])
    }
}

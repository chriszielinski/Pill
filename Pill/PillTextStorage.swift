//
//  PillTextStorage.swift
//  Pill
//
//  Created by Chris Zielinski on 8/21/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Cocoa

open class PillTextStorage: NSTextStorage {

    /// The backing store of the pill text storage object. Use a `NSTextStorage` instance because it does some additional performance 
    /// optimizations over `NSMutableAttributedString`.
    /// 
    public var store: NSTextStorage = NSTextStorage()

    /// Whether the pills (or their metadata) are stale and need to be refreshed before access to `pills`.
    /// 
    private var arePillsDirty: Bool = true
    /// The pill dictionary cache mapping a pill to its character index within the storage.
    /// 
    private var cachedPills: [Pill: Int] = [:]
    /// The pill dictionary mapping a pill to its character index within the storage.
    /// 
    /// - Note: Remember a dictionary's order is unpredictable; thus, no presumption of order should be made.
    /// 
    public var pills: [Pill: Int] {
        if arePillsDirty {
            cachedPills.removeAll()
            store.enumerateAttribute(.attachment, in: NSRange(location: 0, length: store.length), options: .longestEffectiveRangeNotRequired) { (attachment, range, _) in
                guard let pill = attachment as? Pill else { return }
                cachedPills[pill] = range.location
            }
            arePillsDirty = false
        }
        return cachedPills
    }
    /// Whether the receiver contains any pills.
    /// 
    public var hasPills: Bool {
        return !pills.isEmpty
    }

    override public init() {
        super.init()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required public init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
        fatalError("init(pasteboardPropertyList:ofType:) has not been implemented")
    }
}

// MARK: - Subclass Primitive Methods

extension PillTextStorage {
    override open var string: String {
        return store.string
    }

    override open func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedStringKey : Any] {
        return store.attributes(at: location, effectiveRange: range)
    }

    override open func replaceCharacters(in range: NSRange, with str: String) {
        beginEditing()
        store.removeAttribute(.attachment, range: range)
        store.replaceCharacters(in: range, with: str)
        // Note: Casting to NSString is necessary for unicode characters (mostly emojis).
        edited(.editedCharacters, range: range, changeInLength: (str as NSString).length - range.length)
        endEditing()
    }

    override open func setAttributes(_ attrs: [NSAttributedStringKey : Any]?, range: NSRange) {
        beginEditing()
        store.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }

    override open func addAttribute(_ name: NSAttributedStringKey, value: Any, range: NSRange) {
        super.addAttribute(name, value: value, range: range)
        pills(in: range)?.forEach {
            $0.addAttribute(name, value: value)
        }
    }

    override open func removeAttribute(_ name: NSAttributedStringKey, range: NSRange) {
        super.removeAttribute(name, range: range)
        pills(in: range)?.forEach {
            $0.removeAttribute(name)
        }
    }
}

// MARK: - Attribute Modification Methods

public extension PillTextStorage {
    /// Adds an attribute with the given name and value to only the non-pill characters in the receiver.
    /// 
    func addAttributeExcludingPills(_ name: NSAttributedStringKey, value: Any) {
        addAttribute(name, value: value)
        addAttributeToAllPills(name, value: value)
    }

    /// Removes the named attribute from only the non-pill characters in the receiver.
    /// 
    func removeAttributeExcludingPills(_ name: NSAttributedStringKey) {
        removeAttribute(name)
        removeAttributeFromAllPills(name)
    }

    /// Adds an attribute with the given name and value only to the pill characters.
    /// 
    func addAttributeToAllPills(_ name: NSAttributedStringKey, value: Any) {
        pills.keys.forEach { $0.addAttribute(name, value: value) }
    }

    /// Removes the named attribute from only the pill characters.
    /// 
    func removeAttributeFromAllPills(_ name: NSAttributedStringKey) {
        pills.keys.forEach { $0.removeAttribute(name) }
    }
}

// MARK: - Pill Insertion Methods

public extension PillTextStorage {
    /// Replaces the characters and attributes in a given range with the pill.
    /// 
    /// - Parameters: 
    ///     - range: The range of characters and attributes replaced.
    ///     - pill: The pill that will replace the characters and attributes in the specified range.
    func replaceCharacters(in range: NSRange, with pill: Pill) {
        replaceCharacters(in: range, with: pill.attributedStringValue)
    }

    /// Inserts the pill into the receiver at the given character index.
    /// 
    /// - Parameters: 
    ///     - pill: The pill to insert.
    ///     - characterIndex: The character index at which the pill is inserted.
    func insertPill(_ pill: Pill, at characterIndex: Int) {
        insert(pill.attributedStringValue, at: characterIndex)
    }

    /// Adds the pill to the end of the receiver.
    /// 
    /// - Parameter pill: The pill to append.
    func appendPill(_ pill: Pill) {
        append(pill.attributedStringValue)
    }

    /// Replaces the receiver’s entire contents with the characters and parsed pills of the given string. Uses the shared 
    /// `PillDataDetector` to parse pills from `string`.
    /// 
    /// - Parameter string: The string to parse for pills and set.
    func pillifyAndSet(string: String) {
        setAttributedString(PillDataDetector.pillify(string: string))
    }

    /// Replaces the receiver’s entire contents with the characters and pills of the given pill string wrapper.
    /// 
    /// - Parameter pillStringWrapper: The pill string wrapper whose ‘attributedString’ will replace the receiver’s entire contents.
    func setPillStringWrapper(_ pillStringWrapper: PillStringWrapper) {
        setAttributedString(pillStringWrapper.attributedString)
    }
}

// MARK: - Pill Deletion Methods

public extension PillTextStorage {
    /// Deletes the specified pill from the receiver.
    /// 
    /// - Note: This method does not support undo/redo operations.
    /// 
    /// - Parameter characterIndex: The character index of the pill to delete from the receiver.
    func deletePill(at characterIndex: Int) {
        deleteCharacters(in: NSRange(location: characterIndex, length: 1))
    }
}

// MARK: - Pill Query Methods

public extension PillTextStorage {
    /// Returns the character index of a specified pill.
    /// 
    /// - Parameter pill: The pill.
    ///  - Returns: Returns the character index of `pill`, or nil if it is not in the text.
    func characterIndex(of pill: Pill) -> Int? {
        return pills[pill]
    }

    /// Returns the character range of a specified pill.
    /// 
    /// - Parameter pill: The pill.
    ///  - Returns: Returns the character range of `pill`, or nil if it is not in the text.
    func characterRange(of pill: Pill) -> NSRange? {
        guard let characterIndex = characterIndex(of: pill)
            else { return nil }
        return NSRange(location: characterIndex, length: 1)
    }

    /// Returns the pill at a range.
    /// 
    /// - Note: Only returns a non-nil value when the range is the _exact_ location and length of pill, **not** a pill _within_ the 
    /// range.
    /// 
    /// - Parameter range: The range of the pill.
    ///  - Returns: The `PillAttachment` perfectly enclosed by `range`, or nil.
    func pill(at range: NSRange) -> Pill? {
        guard range.length == 1, range.upperBound <= length
            else { return nil }
        return pill(at: range.location)
    }

    /// Returns the pill at a specified character index.
    /// 
    /// - Parameter characterIndex: The character index.
    ///  - Returns: Returns the pill at `characterIndex`, or nil if non-existent.
    func pill(at characterIndex: Int) -> Pill? {
        guard characterIndex >= 0 && characterIndex < length
            else { return nil }
        return attribute(.attachment, at: characterIndex, effectiveRange: nil) as? Pill
    }

    /// Returns the first pill in a specified range.
    /// 
    /// - Parameter characterRange: The character range to search within.
    ///  - Returns: Returns the first pill in `characterRange`, or nil if no such pills exist.
    func firstPill(in characterRange: NSRange) -> Pill? {
        guard hasPills else { return nil }

        var firstPill: Pill?
        enumerateAttribute(.attachment, in: characterRange, options: .longestEffectiveRangeNotRequired) { (attachment, _, shouldStop) in
            guard let pill = attachment as? Pill else { return }
            shouldStop.pointee = true
            firstPill = pill
        }

        return firstPill
    }

    /// Returns all the pills in a specified range.
    /// 
    /// - Parameter range: The character range to search within.
    ///  - Returns: Returns all the pills in `range`.
    func pills(in range: NSRange) -> [Pill]? {
        guard range.length != 0 else {
            if let pill = pill(at: range.location) {
                return [pill]
            }
            return nil
        }

        let pillsInRange = Array(pills.filter { range.contains($0.value) }.keys)
        return pillsInRange.isEmpty ? nil : pillsInRange
    }

    /// Returns the “closest” pill to a specified character index (searching towards the end of the string). Optionally, providing a 
    /// look-behind length that will begin the search offset backwards by that amount (or the beginning of the string if out of 
    /// bounds). Specifying to loop, will search for the first pill in the entire text view if none exist within the aforementioned 
    /// range.
    /// 
    /// - Parameters: 
    ///     - characterIndex: The character index to search from.
    ///     - lookBackLength: The offset to subtract from `characterIndex` before searching. Has a default value of 3.
    ///     - shouldLoop: Whether the search should cycle back to the beginning of the receiver if no other pills exist to the end 
    ///         of the string.
    ///  - Returns: Returns the "closest" pill to a specified character index, or nil if no such pills exist.
    func closestPill(to characterIndex: Int, lookingBack lookBackLength: Int = 3, shouldLoop: Bool = true) -> Pill? {
        let startingIndex = max(0, characterIndex - lookBackLength)
        let toEndRange = NSRange(location: startingIndex, length: length - startingIndex)
        let endPill = firstPill(in: toEndRange)
        // If already found pill OR don't want to loop, return result or nil.
        if endPill != nil || !shouldLoop {
            return endPill
        }
        // Otherwise, search from the beginning.
        let fromStartRange = NSRange(location: 0, length: length - toEndRange.length)
        return firstPill(in: fromStartRange)
    }

    /// Returns the next pill after a specified pill. Optionally, cycling back to the very first pill if none exist after the 
    /// specified pill.
    /// 
    /// - Parameters: 
    ///     - pill: The point-of-reference pill.
    ///     - shouldLoop: Whether the search should cycle back to the first pill if no other pills exist to the end of the string.
    ///  - Returns: The next pill after a specified pill, or nil if no other potential pills exist.
    func pillFollowing(_ pill: Pill, shouldLoop: Bool = true) -> Pill? {
        guard pills.count > 1, let characterIndex = characterIndex(of: pill) else { return nil }

        let sortedPills = pills.sorted { $0.value < $1.value }
        if let followingPill = sortedPills.first(where: { $0.value > characterIndex }) {
            return followingPill.key
        } else if shouldLoop {
            return sortedPills.first?.key
        }

        return nil
    }
}

// MARK: - Overridden Methods

extension PillTextStorage {
    override open func edited(_ editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
        if delta != 0 { arePillsDirty = true }
        super.edited(editedMask, range: editedRange, changeInLength: delta)
    }
}

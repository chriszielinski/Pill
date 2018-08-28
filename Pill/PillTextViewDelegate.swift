//
//  PillTextViewDelegate.swift
//  Pill
//
//  Created by Chris Zielinski on 8/26/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Foundation

public protocol PillTextViewDelegate: class {
    /// Returns the replacement action to perform on the given selected pill for the user interaction.
    ///
    /// - Parameters:
    ///   - pillTextView: The pill text view that contains the selected pill the user interacted with.
    ///   - userInteraction: The type of interaction the user performed on the selected pill.
    ///   - pill: The selected pill the user interacted with.
    /// - Returns: The replacement action for the selected pill.
    func pillTextView(_ pillTextView: PillTextView, userInteraction: Pill.UserInteraction, for pill: Pill) -> Pill.ReplacementAction
}

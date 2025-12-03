//
// Routable.swift
// BigTime
//
// macOS(26.1) with Swift(6.0)
// 03.12.25
//

import SwiftUI

/// Protocol that defines a navigable route in the app
/// Your Route enum should conform to this protocol
@MainActor
public protocol Routable: Hashable, Identifiable, CustomStringConvertible, View {
	/// Unique identifier for the route
	var id: UUID { get }

	/// Human-readable description for logging
	var description: String { get }
}

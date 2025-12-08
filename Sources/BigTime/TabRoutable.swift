//
// TabRoutable.swift
// BigTime
//
// macOS(26.1) with Swift(6.0)
// 03.12.25
//

import Foundation

#if canImport(SwiftUI)
	import SwiftUI
#endif

/// Protocol that defines a tab in a tab-based navigation system
/// Your TabRoute enum should conform to this protocol
@MainActor
public protocol TabRoutable: Hashable, Identifiable, CustomStringConvertible,
	CaseIterable
where AllCases: RandomAccessCollection {
	/// The type of Route this tab uses
	associatedtype RouteType: Routable

	/// The root route to display when this tab is selected
	var rootRoute: RouteType { get }

	/// Display title for the tab
	var title: String { get }

	// In TabRoutable protocol
	#if canImport(SwiftUI)
		var localizedTitle: LocalizedStringKey? { get }
	#endif

	/// SF Symbol icon name for the tab
	var icon: String { get }

	/// Unique identifier for the tab
	var id: String { get }
}

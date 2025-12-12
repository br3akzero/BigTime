//
// Router.swift
// BigTime
//
// macOS(26.1) with Swift(6.0)
// 03.12.25
//

import OSLog
import SwiftUI

/// Represents a single sheet presentation in the hierarchy
public struct SheetPresentation<Route: Routable> {
	let route: Route
	let detents: Set<PresentationDetent>?
	let dragIndicator: Visibility?
	let onDismiss: (() -> Void)?
}

/// Generic router for managing navigation state
/// Initialize with your custom Route type that conforms to Routable
@MainActor
@Observable
public final class Router<Route: Routable> {
	// - State
	/// Navigation stack containing pushed routes
	public var routes: [Route] = []

	/// The root route displayed when the stack is empty
	public var rootRoute: Route

	/// Stack of presented sheets (supports hierarchical sheet presentation)
	public var sheetStack: [SheetPresentation<Route>] = []

	/// Currently presented sheet route (computed from sheetStack for backward compatibility)
	public var sheetRoute: Route? {
		sheetStack.last?.route
	}

	/// Currently presented full screen cover route
	public var fullScreenCoverRoute: Route?

	/// Callback invoked when sheet is dismissed (computed from sheetStack for backward compatibility)
	public var sheetDismissHandler: (() -> Void)? {
		sheetStack.last?.onDismiss
	}

	/// Callback invoked when full screen cover is dismissed
	public var fullScreenCoverDismissHandler: (() -> Void)?

	/// Presentation detents for the sheet (computed from sheetStack for backward compatibility)
	public var sheetPresentationDetents: Set<PresentationDetent>? {
		sheetStack.last?.detents
	}

	/// Drag indicator visibility for the sheet (computed from sheetStack for backward compatibility)
	public var sheetPresentationDragIndicator: Visibility? {
		sheetStack.last?.dragIndicator
	}

	// - Service
	private let log: Logger

	// - Init
	/// Creates a new router with the specified root route
	/// - Parameters:
	///   - root: The initial root route
	///   - subsystem: Optional subsystem identifier for logging (defaults to bundle ID)
	public init(root: Route, subsystem: String? = nil) {
		self.rootRoute = root

		let subsystemID = subsystem ?? Bundle.main.bundleIdentifier ?? "com.bigtime.router"
		self.log = Logger(subsystem: subsystemID, category: "Router")
	}

	// MARK: - Navigation

	/// Pushes a route onto the navigation stack
	/// - Parameter route: The route to push
	public func push(_ route: Route) {
		log.debug("Push route \(route).")
		routes.append(route)
	}

	/// Pops the top route from the navigation stack
	public func pop() {
		log.debug("Pop route.")
		guard !routes.isEmpty else { return }
		routes.removeLast()
	}

	/// Pops all routes from the stack, returning to the root
	public func popToRoot() {
		log.debug("Pop to root route.")
		routes.removeAll()
	}

	/// Switches the root route and clears the navigation stack
	/// - Parameter root: The new root route
	public func switchRoot(_ root: Route) {
		log.debug("Switching root route \(root.description)")
		routes.removeAll()
		rootRoute = root
	}

	// MARK: - Modal Presentation

	/// Presents a route as a sheet
	/// - Parameters:
	///   - route: The route to present
	///   - detents: Presentation detents for the sheet
	///   - dragIndicator: Drag indicator visibility
	///   - onDismiss: Optional callback invoked when the sheet is dismissed
	public func sheet(
		_ route: Route,
		detents: Set<PresentationDetent>? = nil,
		dragIndicator: Visibility? = nil,
		onDismiss: (() -> Void)? = nil
	) {
		log.debug("Presenting sheet for \(route)")

		// Dismiss any active full screen cover first
		if fullScreenCoverRoute != nil {
			log.debug("Dismissing active full screen cover before presenting sheet")
			fullScreenCoverRoute = nil
			fullScreenCoverDismissHandler?()
			fullScreenCoverDismissHandler = nil

			// Wait for dismissal to complete
			Task { @MainActor in
				try? await Task.sleep(for: .milliseconds(350))
				let presentation = SheetPresentation(
					route: route,
					detents: detents,
					dragIndicator: dragIndicator,
					onDismiss: onDismiss
				)
				sheetStack = [presentation]
			}
		} else {
			// No conflicting modal, present immediately
			let presentation = SheetPresentation(
				route: route,
				detents: detents,
				dragIndicator: dragIndicator,
				onDismiss: onDismiss
			)
			sheetStack = [presentation]
		}
	}

	/// Presents a child sheet from within an already-presented sheet
	/// This allows hierarchical sheet presentation (sheet presenting another sheet)
	/// - Parameters:
	///   - route: The route to present as a child sheet
	///   - detents: Presentation detents for the child sheet
	///   - dragIndicator: Drag indicator visibility for the child sheet
	///   - onDismiss: Optional callback invoked when the child sheet is dismissed
	public func childSheet(
		_ route: Route,
		detents: Set<PresentationDetent>? = nil,
		dragIndicator: Visibility? = nil,
		onDismiss: (() -> Void)? = nil
	) {
		guard !sheetStack.isEmpty else {
			log.warning("Attempted to present child sheet without a parent sheet. Use sheet() instead.")
			sheet(route, detents: detents, dragIndicator: dragIndicator, onDismiss: onDismiss)
			return
		}

		log.debug("Presenting child sheet for \(route) (parent: \(self.sheetStack.last?.route.description ?? "unknown"))")

		let presentation = SheetPresentation(
			route: route,
			detents: detents,
			dragIndicator: dragIndicator,
			onDismiss: onDismiss
		)
		sheetStack.append(presentation)
	}

	/// Presents a route as a full screen cover
	/// - Parameters:
	///   - route: The route to present
	///   - onDismiss: Optional callback invoked when the cover is dismissed
	public func fullScreenCover(
		_ route: Route,
		onDismiss: (() -> Void)? = nil
	) {
		log.debug("Full screen cover route pushed \(route).")

		// Dismiss any active sheet first
		if !sheetStack.isEmpty {
			log.debug("Dismissing active sheet(s) before presenting full screen cover")
			dismissAllSheets()

			// Wait for dismissal to complete
			Task { @MainActor in
				try? await Task.sleep(for: .milliseconds(350))
				fullScreenCoverRoute = route
				fullScreenCoverDismissHandler = onDismiss
			}
		} else {
			// No conflicting modal, present immediately
			fullScreenCoverRoute = route
			fullScreenCoverDismissHandler = onDismiss
		}
	}

	/// Dismisses the currently presented sheet
	/// If there are child sheets, dismisses the topmost child and returns to its parent
	/// If there's only one sheet, dismisses it entirely
	public func dismissSheet() {
		guard !sheetStack.isEmpty else { return }

		let dismissedSheet = sheetStack.removeLast()

		if sheetStack.isEmpty {
			log.debug("Dismissing sheet: \(dismissedSheet.route.description)")
		} else {
			log.debug("Dismissing child sheet: \(dismissedSheet.route.description), returning to parent: \(self.sheetStack.last?.route.description ?? "unknown")")
		}

		dismissedSheet.onDismiss?()
	}

	/// Dismisses all sheets in the hierarchy
	public func dismissAllSheets() {
		guard !sheetStack.isEmpty else { return }

		log.debug("Dismissing all \(self.sheetStack.count) sheet(s)")

		// Call dismiss handlers in reverse order (from child to parent)
		for presentation in sheetStack.reversed() {
			presentation.onDismiss?()
		}

		sheetStack.removeAll()
	}

	/// Dismisses the currently presented full screen cover
	public func dismissFullScreenCover() {
		guard fullScreenCoverRoute != nil else { return }
		log.debug("Dismiss full screen cover.")

		fullScreenCoverRoute = nil
		fullScreenCoverDismissHandler?()
		fullScreenCoverDismissHandler = nil
	}
}

//
// Router.swift
// BigTime
//
// macOS(26.1) with Swift(6.0)
// 03.12.25
//

import OSLog
import SwiftUI

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

	/// Currently presented sheet route
	public var sheetRoute: Route?

	/// Currently presented full screen cover route
	public var fullScreenCoverRoute: Route?

	/// Callback invoked when sheet is dismissed
	public var sheetDismissHandler: (() -> Void)?

	/// Callback invoked when full screen cover is dismissed
	public var fullScreenCoverDismissHandler: (() -> Void)?

	/// Presentation detents for the sheet
	public var sheetPresentationDetents: Set<PresentationDetent>?

	/// Drag indicator visibility for the sheet
	public var sheetPresentationDragIndicator: Visibility?

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
		log.debug("Push route \(route):\(route.id).")
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
		log.debug("Switching root route \(root.id)")
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
		log.debug("Presenting sheet for \(route):\(route.id)")

		// Dismiss any active full screen cover first
		if fullScreenCoverRoute != nil {
			log.debug("Dismissing active full screen cover before presenting sheet")
			fullScreenCoverRoute = nil
			fullScreenCoverDismissHandler?()
			fullScreenCoverDismissHandler = nil

			// Wait for dismissal to complete
			Task { @MainActor in
				try? await Task.sleep(for: .milliseconds(350))
				sheetRoute = route
				sheetDismissHandler = onDismiss
				sheetPresentationDetents = detents
				sheetPresentationDragIndicator = dragIndicator
			}
		} else {
			// No conflicting modal, present immediately
			sheetRoute = route
			sheetDismissHandler = onDismiss
			sheetPresentationDetents = detents
			sheetPresentationDragIndicator = dragIndicator
		}
	}

	/// Presents a route as a full screen cover
	/// - Parameters:
	///   - route: The route to present
	///   - onDismiss: Optional callback invoked when the cover is dismissed
	public func fullScreenCover(
		_ route: Route,
		onDismiss: (() -> Void)? = nil
	) {
		log.debug("Full screen cover route pushed \(route):\(route.id).")

		// Dismiss any active sheet first
		if sheetRoute != nil {
			log.debug("Dismissing active sheet before presenting full screen cover")
			sheetRoute = nil
			sheetDismissHandler?()
			sheetDismissHandler = nil

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
	public func dismissSheet() {
		guard sheetRoute != nil else { return }

		log.debug("Dismiss top most sheet.")

		sheetRoute = nil
		sheetDismissHandler?()
		sheetDismissHandler = nil
		sheetPresentationDetents = nil
		sheetPresentationDragIndicator = nil
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

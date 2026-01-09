//
// TabRouter.swift
// BigTime
//
// macOS(26.1) with Swift(6.0)
// 03.12.25
//

import OSLog
import SwiftUI

/// Generic tab router that manages independent Router instances for each tab
/// Ensures complete isolation between tab navigation stacks
@MainActor
@Observable
public final class TabRouter<TabRoute: TabRoutable> {
	// - State
	/// Currently selected tab
	public var selectedTab: TabRoute

	/// Independent routers for each tab
	public private(set) var routers: [TabRoute: Router<TabRoute.RouteType>]

	/// Currently displayed universal overlay route (persists across tab switches)
	public var universalOverlayRoute: TabRoute.RouteType?

	// - Service
	private let log: Logger

	// - Init
	/// Creates a new tab router
	/// - Parameters:
	///   - selectedTab: The initially selected tab (defaults to first tab in allCases)
	///   - subsystem: Optional subsystem identifier for logging (defaults to bundle ID)
	public init(
		selectedTab: TabRoute? = nil,
		subsystem: String? = nil
	) {
		// Use provided tab or default to first tab
		self.selectedTab = selectedTab ?? TabRoute.allCases.first!

		let subsystemID = subsystem ?? Bundle.main.bundleIdentifier ?? "com.bigtime.tabrouter"
		self.log = Logger(subsystem: subsystemID, category: "TabRouter")

		// Initialize a Router for each tab
		self.routers = [:]
		for tab in TabRoute.allCases {
			let router = Router(root: tab.rootRoute, subsystem: subsystemID)
			router.onOverlayPresenting = { [weak self] in
				self?.dismissUniversalOverlay()
			}
			self.routers[tab] = router
		}

		log.debug("TabRouter initialized with \(TabRoute.allCases.count) tabs")
	}

	// MARK: - Computed

	/// Get the router for the currently selected tab
	public var currentRouter: Router<TabRoute.RouteType> {
		router(for: selectedTab)
	}

	/// Get the router for a specific tab
	/// - Parameter tab: The tab to get the router for
	/// - Returns: The router for the specified tab
	public func router(for tab: TabRoute) -> Router<TabRoute.RouteType> {
		guard let router = routers[tab] else {
			let newRouter = Router(root: tab.rootRoute)
			routers[tab] = newRouter
			return newRouter
		}

		return router
	}

	// MARK: - Tab Switching

	/// Switches to a different tab
	/// - Parameter tab: The tab to switch to
	public func switchTab(to tab: TabRoute) {
		guard tab != selectedTab else { return }

		log.debug("Switching from \(self.selectedTab) to \(tab)")
		selectedTab = tab
	}

	// MARK: - Universal Overlay

	/// Present a universal overlay that persists across tab switches
	/// - Parameters:
	///   - route: The route to display as overlay
	///   - animation: Optional animation for the presentation
	public func universalOverlay(_ route: TabRoute.RouteType, animation: Animation? = .default) {
		log.debug("TabRouter universal overlay presented: \(route.description)")

		// Dismiss any router-level overlays for mutual exclusion
		for router in routers.values {
			if router.hasUniversalOverlay {
				router.dismissUniversalOverlay(animation: animation)
			}
		}

		withAnimation(animation) {
			universalOverlayRoute = route
		}
	}

	/// Dismiss the current universal overlay
	/// - Parameter animation: Optional animation for the dismissal
	public func dismissUniversalOverlay(animation: Animation? = .default) {
		guard universalOverlayRoute != nil else { return }
		log.debug("TabRouter universal overlay dismissed")
		withAnimation(animation) {
			universalOverlayRoute = nil
		}
	}

	/// Check if a universal overlay is currently presented at TabRouter level
	public var hasUniversalOverlay: Bool {
		universalOverlayRoute != nil
	}
}

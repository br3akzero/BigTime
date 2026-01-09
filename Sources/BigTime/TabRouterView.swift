//
// TabRouterView.swift
// BigTime
//
// macOS(26.1) with Swift(6.0)
// 03.12.25
//

import SwiftUI

/// Generic view that manages tab-based navigation
/// Each tab maintains its own independent navigation stack via Router
public struct TabRouterView<TabRoute: TabRoutable>: View {
	// - State
	@State
	public var tabRouter: TabRouter<TabRoute>

	/// Optional callback for screen view tracking
	/// Called with the route's description whenever a new screen is displayed
	public var onScreenView: ((String) -> Void)?

	// - Init
	/// Creates a TabRouterView with a tab router
	/// - Parameters:
	///   - tabRouter: The tab router to use
	///   - onScreenView: Optional callback for tracking screen views
	public init(
		tabRouter: TabRouter<TabRoute>,
		onScreenView: ((String) -> Void)? = nil
	) {
		self._tabRouter = State(initialValue: tabRouter)
		self.onScreenView = onScreenView
	}

	/// Creates a TabRouterView with an initial tab selection
	/// - Parameters:
	///   - selectedTab: The initially selected tab
	///   - subsystem: Optional subsystem identifier for logging
	///   - onScreenView: Optional callback for tracking screen views
	public init(
		selectedTab: TabRoute? = nil,
		subsystem: String? = nil,
		onScreenView: ((String) -> Void)? = nil
	) {
		self._tabRouter = State(
			initialValue: TabRouter(selectedTab: selectedTab, subsystem: subsystem)
		)
		self.onScreenView = onScreenView
	}

	// - Render
	public var body: some View {
		ZStack(alignment: .bottom) {
			TabView(selection: $tabRouter.selectedTab) {
				ForEach(TabRoute.allCases, id: \.id) { tab in
					RouterView(
						router: tabRouter.router(for: tab),
						onScreenView: onScreenView
					)
					.disableUniversalOverlay()
					.tag(tab)
					.tabItem {
						if let localizedTitle = tab.localizedTitle {
							Label(localizedTitle, systemImage: tab.icon)
						} else {
							Label(tab.title, systemImage: tab.icon)
						}
					}
				}
			}

			// Universal overlay - prefer TabRouter level, fallback to current router's
			if let overlayRoute = tabRouter.universalOverlayRoute {
				overlayRoute
					.transition(.move(edge: .bottom).combined(with: .opacity))
					.zIndex(1)
			} else if let overlayRoute = tabRouter.currentRouter.universalOverlayRoute {
				overlayRoute
					.transition(.move(edge: .bottom).combined(with: .opacity))
					.zIndex(1)
			}
		}
		.environment(tabRouter)
		.environment(tabRouter.currentRouter)
	}
}

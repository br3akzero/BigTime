//
// RouterView.swift
// BigTime
//
// macOS(26.1) with Swift(6.0)
// 03.12.25
//

import SwiftUI

/// Generic view that manages navigation using a Router
/// Provides push navigation, sheet presentation, and full screen covers
public struct RouterView<Route: Routable>: View {
	// - State
	@Bindable
	public var router: Router<Route>

	/// Optional callback for screen view tracking
	/// Called with the route's description whenever a new screen is displayed
	public var onScreenView: ((String) -> Void)?

	// - Init
	/// Creates a RouterView with an existing router
	/// - Parameters:
	///   - router: The router to use for navigation
	///   - onScreenView: Optional callback for tracking screen views
	public init(
		router: Router<Route>,
		onScreenView: ((String) -> Void)? = nil
	) {
		self.router = router
		self.onScreenView = onScreenView
	}

	/// Creates a RouterView with a root route
	/// - Parameters:
	///   - root: The initial root route
	///   - subsystem: Optional subsystem identifier for logging
	///   - onScreenView: Optional callback for tracking screen views
	public init(
		root: Route,
		subsystem: String? = nil,
		onScreenView: ((String) -> Void)? = nil
	) {
		self.router = Router(root: root, subsystem: subsystem)
		self.onScreenView = onScreenView
	}

	// - Render
	public var body: some View {
		NavigationStack(path: $router.routes) {
			router
				.rootRoute
				.navigationDestination(for: Route.self) { screen in
					screen
						.onAppear {
							onScreenView?(screen.description)
						}
				}
		}
		.environment(router)
		.sheet(
			item: $router.sheetRoute,
			onDismiss: router.sheetDismissHandler
		) { route in
			NavigationStack {
				route
					.environment(router)
					.onAppear {
						onScreenView?(route.description)
					}
			}
			.presentationDetents(router.sheetPresentationDetents ?? [.large])
			.presentationDragIndicator(router.sheetPresentationDragIndicator ?? .automatic)
		}
		#if !os(macOS)
			.fullScreenCover(
				item: $router.fullScreenCoverRoute,
				onDismiss: router.fullScreenCoverDismissHandler
			) { route in
				NavigationStack {
					route
						.environment(router)
						.onAppear {
							onScreenView?(route.description)
						}
				}
			}
		#endif
	}
}

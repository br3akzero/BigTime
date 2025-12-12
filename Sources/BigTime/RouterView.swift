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
		.hierarchicalSheet(
			stack: router.sheetStack,
			level: 0,
			onScreenView: onScreenView,
			router: router
		)
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

// MARK: - Hierarchical Sheet Support

/// Internal view modifier that handles hierarchical sheet presentation
private struct HierarchicalSheetModifier<Route: Routable>: ViewModifier {
	let stack: [SheetPresentation<Route>]
	let level: Int
	let onScreenView: ((String) -> Void)?
	let router: Router<Route>

	func body(content: Content) -> some View {
		content
			.sheet(isPresented: .constant(level < stack.count)) {
				if level < stack.count {
					let presentation = stack[level]
					NavigationStack {
						presentation.route
							.environment(router)
							.onAppear {
								onScreenView?(presentation.route.description)
							}
					}
					.presentationDetents(presentation.detents ?? [.large])
					.presentationDragIndicator(presentation.dragIndicator ?? .automatic)
					.hierarchicalSheet(
						stack: stack,
						level: level + 1,
						onScreenView: onScreenView,
						router: router
					)
					.interactiveDismissDisabled(false)
					.onDisappear {
						// Handle dismissal when user swipes down to dismiss
						// Only call if this is still the top sheet
						if router.sheetStack.count > level {
							router.dismissSheet()
						}
					}
				}
			}
	}
}

extension View {
	/// Applies hierarchical sheet presentation to a view
	fileprivate func hierarchicalSheet<Route: Routable>(
		stack: [SheetPresentation<Route>],
		level: Int,
		onScreenView: ((String) -> Void)?,
		router: Router<Route>
	) -> some View {
		modifier(HierarchicalSheetModifier(
			stack: stack,
			level: level,
			onScreenView: onScreenView,
			router: router
		))
	}
}

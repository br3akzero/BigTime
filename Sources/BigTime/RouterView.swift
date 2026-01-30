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

	@Environment(\.universalOverlayDisabled)
	private var universalOverlayDisabled

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
		ZStack(alignment: .bottom) {
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

			// Universal overlay layer (disabled when used inside TabRouterView)
			if !universalOverlayDisabled, let overlayRoute = router.universalOverlayRoute {
				overlayRoute
					.transition(.move(edge: .bottom).combined(with: .opacity))
					.zIndex(1)
			}
		}
		.environment(router)
		.hierarchicalSheet(
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

/// Wrapper to make SheetPresentation identifiable for sheet(item:) binding
private struct IdentifiableSheetPresentation<Route: Routable>: Identifiable {
	let presentation: SheetPresentation<Route>
	let level: Int

	var id: String {
		"\(level)-\(presentation.route.id)"
	}
}

/// Internal view modifier that handles hierarchical sheet presentation
private struct HierarchicalSheetModifier<Route: Routable>: ViewModifier {
	let level: Int
	let onScreenView: ((String) -> Void)?
	@Bindable var router: Router<Route>

	private var sheetItem: Binding<IdentifiableSheetPresentation<Route>?> {
		Binding(
			get: {
				guard level < router.sheetStack.count else { return nil }
				return IdentifiableSheetPresentation(
					presentation: router.sheetStack[level],
					level: level
				)
			},
			set: { newValue in
				if newValue == nil && level < router.sheetStack.count {
					// Sheet was dismissed by user gesture
					// Dismiss from the top down to this level
					while router.sheetStack.count > level {
						router.dismissSheet()
					}
				}
			}
		)
	}

	func body(content: Content) -> some View {
		content
			.sheet(item: sheetItem) { item in
				NavigationStack {
					item.presentation.route
						.environment(router)
						.onAppear {
							onScreenView?(item.presentation.route.description)
						}
				}
				.presentationDetents(item.presentation.detents ?? [.large])
				.presentationDragIndicator(item.presentation.dragIndicator ?? .automatic)
				.hierarchicalSheet(
					level: level + 1,
					onScreenView: onScreenView,
					router: router
				)
			}
	}
}

extension View {
	/// Applies hierarchical sheet presentation to a view
	fileprivate func hierarchicalSheet<Route: Routable>(
		level: Int,
		onScreenView: ((String) -> Void)?,
		router: Router<Route>
	) -> some View {
		modifier(HierarchicalSheetModifier(
			level: level,
			onScreenView: onScreenView,
			router: router
		))
	}
}

//
// RouterView+UniversalOverlay.swift
// BigTime
//
// macOS(26.1) with Swift(6.0)
// 08.01.26
//

import SwiftUI

// MARK: - Environment Key for Universal Overlay

private struct UniversalOverlayDisabledKey: EnvironmentKey {
	static let defaultValue: Bool = false
}

extension EnvironmentValues {
	var universalOverlayDisabled: Bool {
		get { self[UniversalOverlayDisabledKey.self] }
		set { self[UniversalOverlayDisabledKey.self] = newValue }
	}
}

extension View {
	/// Disables universal overlay rendering for this view hierarchy
	/// Use this when embedding RouterView inside TabRouterView to prevent duplicate overlays
	public func disableUniversalOverlay() -> some View {
		environment(\.universalOverlayDisabled, true)
	}
}

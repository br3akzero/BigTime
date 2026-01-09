# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BigTime is a type-safe, protocol-driven navigation framework for SwiftUI applications. It provides a reusable routing system supporting push navigation, sheet presentations, full-screen covers, and tab-based navigation with independent stacks per tab.

## Build and Test Commands

```bash
# Build the package
swift build

# Run tests
swift test

# Build for specific platform
swift build -c release

# Generate and open documentation (if using DocC)
swift package generate-documentation --target BigTime
```

## Architecture

### Core Components

The framework is built around two primary router types and their corresponding protocols:

1. **Router<Route>** (Router.swift:16) - Manages single-stack navigation
   - Handles push navigation via NavigationStack
   - Manages sheet and full-screen cover presentations
   - Uses `@Observable` for SwiftUI state management
   - Implements conflict resolution when presenting modals (one modal at a time)
   - Contains 350ms delay when switching between modal types to allow dismissal animations

2. **TabRouter<TabRoute>** (TabRouter.swift:16) - Manages multi-tab navigation
   - Creates independent Router instances for each tab
   - Maintains complete isolation between tab navigation stacks
   - Each tab has its own push/modal state
   - Supports TabRouter-level universal overlay that persists across tab switches

### Protocol Architecture

**Routable** (Routable.swift:14) - Protocol for defining navigable routes
- Must be used on `@MainActor` only
- Combines: `Hashable` (for NavigationStack), `Identifiable` (for SwiftUI), `CustomStringConvertible` (for logging), `View` (to render)
- The Route enum itself IS the View - switch statement in the body renders different screens

**TabRoutable** (TabRoutable.swift:18) - Protocol for defining tabs
- Must be used on `@MainActor` only
- Associates a `RouteType: Routable` for each tab's navigation
- Requires `CaseIterable` to enumerate all tabs
- Provides `rootRoute`, `title`, `icon`, and `id` for each tab
- Supports optional `localizedTitle: LocalizedStringKey?` for localized tab labels

### View Layer

**RouterView** (RouterView.swift:13) - SwiftUI view wrapping Router
- Embeds Router in SwiftUI Environment for child access via `@Environment(Router<Route>.self)`
- Binds NavigationStack path to `router.routes` array
- Manages sheet/fullScreenCover presentation via bindings
- Optional `onScreenView` callback for analytics tracking
- Note: fullScreenCover is `#if !os(macOS)` only (macOS uses sheets)

**TabRouterView** (TabRouterView.swift:13) - SwiftUI view wrapping TabRouter
- Creates TabView bound to `tabRouter.selectedTab`
- Renders a RouterView for each tab with its isolated Router
- Each tab maintains independent navigation state
- Embeds TabRouter in Environment for `@Environment(TabRouter<TabRoute>.self)` access

### Key Design Patterns

1. **Environment-based access** - Routers are injected via SwiftUI Environment, accessed with `@Environment(Router<Route>.self)` or `@Environment(TabRouter<TabRoute>.self)`

2. **Modal conflict resolution** - Router prevents presenting sheet + fullScreenCover simultaneously by dismissing one before showing the other

3. **Route-as-View** - Routes ARE Views; the enum body renders the appropriate screen. No separate view mapping needed.

4. **Logging with OSLog** - Both routers use structured logging with customizable subsystem identifiers

5. **Dismiss handlers** - Optional callbacks execute after modal dismissal (e.g., refresh data after settings closed)

6. **Automatic hierarchical sheets** - The `sheet()` method automatically detects if it's called from within an existing sheet and creates a child sheet. No need for separate `childSheet()` method. Uses a `sheetStack: [SheetPresentation<Route>]` internally to track the hierarchy (Router.swift:147-157).

7. **Universal overlay** - Persistent overlay views that float above navigation content but below modals. Accessed via `router.universalOverlay()`. TabRouterView renders the current tab's overlay above the tab bar.

## Important Constraints

- **@MainActor requirement**: Both `Routable` and `TabRoutable` protocols require `@MainActor`. All Route and TabRoute enums MUST be marked `@MainActor`.

- **Platform limitations**: fullScreenCover is not available on macOS (sheets are used instead). Code is conditionally compiled with `#if !os(macOS)`.

- **Swift 6.0 required**: Package uses Swift 6.0 with full concurrency support. All code must respect strict concurrency checking.

- **Minimum platform versions**: iOS 17, macOS 14, watchOS 11, tvOS 17, visionOS 1 (as defined in Package.swift:8-13)

## Hierarchical Sheet Presentation

The framework supports presenting sheets from within sheets (child sheets) with automatic detection:

- Call `router.sheet()` anywhere - it automatically detects context
- If no sheet is currently presented, creates a new root sheet
- If called from within a sheet, appends to the `sheetStack` as a child
- `dismissSheet()` pops from the stack (returns to parent if hierarchy exists)
- `dismissAllSheets()` clears entire stack and invokes all dismiss handlers in reverse order
- Each sheet in the hierarchy can have its own detents, drag indicators, and dismiss handlers
- RouterView uses recursive `HierarchicalSheetModifier` to present each level (RouterView.swift:88-124)

## Universal Overlay

The framework supports persistent overlay views that float above navigation content but below modal presentations (sheets/covers). Common use cases include mini-players, floating action buttons, or persistent banners.

**Two Overlay Scopes:**
1. **Router-level overlay** - Tied to a specific Router instance. In TabRouterView, dismissed when switching tabs.
2. **TabRouter-level overlay** - Persists across tab switches. Use when overlay should remain visible regardless of selected tab.

**Mutual Exclusion:** Only one overlay can be active at a time. Presenting a TabRouter overlay dismisses any Router overlay, and vice versa. This is enforced via `onOverlayPresenting` callback on Router (Router.swift:54-56).

**Router API:**
- `universalOverlayRoute: Route?` - The currently displayed overlay route
- `universalOverlay(_:animation:)` - Present an overlay with optional animation
- `dismissUniversalOverlay(animation:)` - Dismiss the overlay with optional animation
- `hasUniversalOverlay: Bool` - Check if an overlay is currently presented
- `onOverlayPresenting: (() -> Void)?` - Internal callback for mutual exclusion coordination

**TabRouter API:**
- `universalOverlayRoute: TabRoute.RouteType?` - The currently displayed overlay route (persists across tabs)
- `universalOverlay(_:animation:)` - Present an overlay with optional animation
- `dismissUniversalOverlay(animation:)` - Dismiss the overlay with optional animation
- `hasUniversalOverlay: Bool` - Check if an overlay is currently presented

**View Modifier:**
- `disableUniversalOverlay()` - Disables overlay rendering in a view hierarchy (used internally by TabRouterView)

**Layer Order:**
1. NavigationStack / TabView (base content)
2. Universal Overlay (ZStack layer)
3. Sheets (above overlay)
4. Full Screen Cover (top layer)

**TabRouterView Integration:**
- TabRouterView uses `.disableUniversalOverlay()` on child RouterViews to prevent duplicate overlay rendering
- Prioritizes TabRouter's overlay, falls back to current router's overlay (TabRouterView.swift:72-81)
- Overlays render above the TabView and tab bar

## Testing

Tests use Swift Testing framework (`import Testing`). Current test coverage is minimal (see Tests/BigTimeTests/BigTimeTests.swift:4-6).

When adding tests, focus on:
- Router navigation stack manipulation (push/pop/popToRoot/switchRoot)
- Modal presentation state management and conflict resolution
- Hierarchical sheet presentation and dismissal
- TabRouter tab switching and stack isolation
- Dismiss handler invocation
- Universal overlay mutual exclusion between Router and TabRouter

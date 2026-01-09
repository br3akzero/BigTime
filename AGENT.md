# Agent.md - BigTime Navigation Framework Guide for AI Agents

This guide explains how to implement navigation in SwiftUI apps using the BigTime framework. Follow these patterns exactly.

## Quick Reference

```swift
import BigTime

// Access router from any view
@Environment(Router<AppRoute>.self) var router

// Navigation actions
router.push(.detail(id: "123"))    // Push onto stack
router.pop()                        // Pop one level
router.popToRoot()                  // Return to root
router.switchRoot(.home)           // Change root route

// Modal presentation
router.sheet(.settings)                                    // Present sheet
router.sheet(.picker, detents: [.medium])                  // Sheet with detents
router.fullScreenCover(.onboarding)                        // Full screen (iOS only)
router.dismissSheet()                                      // Dismiss current sheet
router.dismissAllSheets()                                  // Dismiss entire sheet stack
router.dismissFullScreenCover()                            // Dismiss full screen cover

// Universal overlay (persistent view above content, below modals)
router.universalOverlay(.miniPlayer(station))              // Router-level overlay
router.dismissUniversalOverlay()                           // Dismiss router overlay
router.hasUniversalOverlay                                 // Check if overlay active

// TabRouter-level overlay (persists across tab switches)
tabRouter.universalOverlay(.miniPlayer(station))           // TabRouter-level overlay
tabRouter.dismissUniversalOverlay()                        // Dismiss tabRouter overlay
tabRouter.hasUniversalOverlay                              // Check if overlay active
```

## Step 1: Define Your Routes

Create an enum that conforms to `Routable`. The enum IS the view - implement the `body` property to render screens.

```swift
import BigTime
import SwiftUI

@MainActor  // REQUIRED - all Route enums must be @MainActor
enum AppRoute: Routable {
    case home
    case detail(id: String)
    case settings
    case profile(user: User)

    // REQUIRED: Unique identifier for SwiftUI
    var id: String {
        switch self {
        case .home: "home"
        case .detail(let id): "detail-\(id)"
        case .settings: "settings"
        case .profile(let user): "profile-\(user.id)"
        }
    }

    // REQUIRED: Logging description
    var description: String {
        switch self {
        case .home: "Home"
        case .detail(let id): "Detail(\(id))"
        case .settings: "Settings"
        case .profile(let user): "Profile(\(user.name))"
        }
    }

    // REQUIRED: The view to render for each route
    var body: some View {
        switch self {
        case .home:
            HomeView()
        case .detail(let id):
            DetailView(itemId: id)
        case .settings:
            SettingsView()
        case .profile(let user):
            ProfileView(user: user)
        }
    }
}
```

## Step 2: Set Up RouterView at App Root

Wrap your app content in `RouterView` to enable navigation.

```swift
import BigTime
import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            RouterView(root: AppRoute.home)
        }
    }
}
```

With analytics tracking:

```swift
RouterView(root: AppRoute.home) { screenName in
    Analytics.trackScreenView(screenName)
}
```

## Step 3: Navigate From Any View

Access the router via environment and call navigation methods.

```swift
struct HomeView: View {
    @Environment(Router<AppRoute>.self) var router

    var body: some View {
        List {
            Button("View Details") {
                router.push(.detail(id: "item-1"))
            }

            Button("Open Settings") {
                router.sheet(.settings)
            }
        }
        .navigationTitle("Home")
    }
}
```

## Tab-Based Navigation

For apps with tabs, use `TabRoutable` and `TabRouterView`.

### Step 1: Define Tab Routes

Each tab needs its own `Routable` enum for its navigation stack:

```swift
@MainActor
enum HomeRoute: Routable {
    case feed
    case postDetail(id: String)

    var id: String {
        switch self {
        case .feed: "feed"
        case .postDetail(let id): "post-\(id)"
        }
    }

    var description: String {
        switch self {
        case .feed: "Feed"
        case .postDetail(let id): "Post(\(id))"
        }
    }

    var body: some View {
        switch self {
        case .feed: FeedView()
        case .postDetail(let id): PostDetailView(postId: id)
        }
    }
}

@MainActor
enum ProfileRoute: Routable {
    case profile
    case editProfile

    var id: String {
        switch self {
        case .profile: "profile"
        case .editProfile: "edit-profile"
        }
    }

    var description: String {
        switch self {
        case .profile: "Profile"
        case .editProfile: "Edit Profile"
        }
    }

    var body: some View {
        switch self {
        case .profile: ProfileView()
        case .editProfile: EditProfileView()
        }
    }
}
```

### Step 2: Define Tabs

Create a `TabRoutable` enum. All tabs must share the same Route type:

```swift
@MainActor
enum AppTab: TabRoutable {
    case home
    case search
    case profile

    // All tabs use the same Route type
    typealias RouteType = AppRoute

    var rootRoute: AppRoute {
        switch self {
        case .home: .home
        case .search: .search
        case .profile: .profile
        }
    }

    var title: String {
        switch self {
        case .home: "Home"
        case .search: "Search"
        case .profile: "Profile"
        }
    }

    var icon: String {
        switch self {
        case .home: "house"
        case .search: "magnifyingglass"
        case .profile: "person"
        }
    }

    var id: String {
        switch self {
        case .home: "home"
        case .search: "search"
        case .profile: "profile"
        }
    }

    var description: String { title }
}
```

### Step 3: Use TabRouterView

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            TabRouterView<AppTab>()
        }
    }
}
```

### Accessing TabRouter

```swift
struct SomeView: View {
    @Environment(TabRouter<AppTab>.self) var tabRouter

    var body: some View {
        Button("Go to Profile") {
            tabRouter.switchTab(to: .profile)
        }
    }
}
```

## Sheet Presentation Patterns

### Basic Sheet

```swift
router.sheet(.settings)
```

### Sheet with Detents

```swift
router.sheet(.picker, detents: [.medium, .large])
```

### Sheet with Drag Indicator

```swift
router.sheet(.picker, dragIndicator: .visible)
```

### Sheet with Dismiss Handler

Execute code after sheet dismissal:

```swift
router.sheet(.editItem(item)) {
    // Called after sheet is dismissed
    refreshData()
}
```

### Hierarchical Sheets (Sheets from Sheets)

Call `sheet()` from within a sheet - BigTime automatically handles the hierarchy:

```swift
// In SettingsView (already presented as a sheet)
struct SettingsView: View {
    @Environment(Router<AppRoute>.self) var router

    var body: some View {
        Button("Select Theme") {
            // Automatically presents as a child sheet
            router.sheet(.themePicker)
        }
    }
}
```

Dismissal behavior:
- `dismissSheet()` - Dismisses topmost sheet, returns to parent
- `dismissAllSheets()` - Dismisses entire sheet stack

## Full Screen Cover (iOS/tvOS/watchOS only)

```swift
router.fullScreenCover(.onboarding)

router.fullScreenCover(.onboarding) {
    // Called after dismissal
    markOnboardingComplete()
}

router.dismissFullScreenCover()
```

Note: `fullScreenCover` is not available on macOS. The framework uses conditional compilation and falls back to sheets.

## Universal Overlay

Present persistent views that float above navigation content but below modals. Common use cases include mini-players, floating action buttons, or persistent banners.

### Two Overlay Scopes

1. **Router-level overlay** - For standalone `RouterView` usage. Tied to a specific router.
2. **TabRouter-level overlay** - For `TabRouterView` usage. Persists across tab switches.

**Mutual exclusion:** Only one overlay can be active at a time. Presenting a TabRouter overlay automatically dismisses any Router overlay, and vice versa.

### Basic Usage

```swift
// Router-level overlay (dismissed when switching tabs)
router.universalOverlay(.miniPlayer(station))
router.dismissUniversalOverlay()

// TabRouter-level overlay (persists across tabs)
tabRouter.universalOverlay(.miniPlayer(station))
tabRouter.dismissUniversalOverlay()

// Present with custom animation
router.universalOverlay(.floatingButton, animation: .spring())

// Check if overlay is active
if router.hasUniversalOverlay {
    // Adjust layout padding
}
if tabRouter.hasUniversalOverlay {
    // Adjust layout padding
}
```

### Example: Mini Player Overlay

```swift
@MainActor
enum AppRoute: Routable {
    case home
    case stationList
    case miniPlayer(station: Station)  // Used for overlay

    var id: String {
        switch self {
        case .home: "home"
        case .stationList: "station-list"
        case .miniPlayer(let station): "mini-player-\(station.id)"
        }
    }

    var description: String {
        switch self {
        case .home: "Home"
        case .stationList: "Station List"
        case .miniPlayer(let station): "Mini Player: \(station.name)"
        }
    }

    var body: some View {
        switch self {
        case .home: HomeView()
        case .stationList: StationListView()
        case .miniPlayer(let station): MiniPlayerView(station: station)
        }
    }
}

struct StationListView: View {
    @Environment(Router<AppRoute>.self) var router

    var body: some View {
        List(stations) { station in
            Button(station.name) {
                router.universalOverlay(.miniPlayer(station: station))
            }
        }
    }
}

struct MiniPlayerView: View {
    @Environment(Router<AppRoute>.self) var router
    let station: Station

    var body: some View {
        HStack {
            Text(station.name)
            Spacer()
            Button("Close") {
                router.dismissUniversalOverlay()
            }
        }
        .frame(height: 64)
        .background(.ultraThinMaterial)
    }
}
```

### Layer Order

Overlays appear in this order (bottom to top):
1. Navigation content (NavigationStack/TabView)
2. **Universal Overlay**
3. Sheets
4. Full Screen Cover

### TabRouterView Integration

When using `TabRouterView`, overlays render above the tab bar. Use `tabRouter.universalOverlay()` for overlays that should persist across tab switches.

```swift
struct ContentView: View {
    @Environment(Router<AppRoute>.self) var router
    @Environment(TabRouter<AppTab>.self) var tabRouter

    var body: some View {
        ScrollView {
            // Content...
        }
        // Add bottom padding when overlay is visible
        .safeAreaPadding(.bottom, (router.hasUniversalOverlay || tabRouter.hasUniversalOverlay) ? 80 : 0)
    }
}

// Present overlay that persists across tabs
tabRouter.universalOverlay(.miniPlayer(station))
```

## Critical Constraints

### 1. @MainActor Requirement

All `Routable` and `TabRoutable` enums MUST be marked `@MainActor`:

```swift
@MainActor  // REQUIRED
enum AppRoute: Routable {
    // ...
}
```

### 2. Modal Conflict Resolution

BigTime prevents presenting sheet + fullScreenCover simultaneously. If you call `sheet()` while a fullScreenCover is active (or vice versa), it automatically:
1. Dismisses the current modal
2. Waits 350ms for animation
3. Presents the new modal

### 3. Route Must Be Hashable

Associated values in routes must conform to `Hashable`:

```swift
// Good - String is Hashable
case detail(id: String)

// Good - if User conforms to Hashable
case profile(user: User)

// Bad - unless MyClass is Hashable
case item(object: MyClass)
```

### 4. Platform Requirements

- iOS 17+
- macOS 14+
- watchOS 11+
- tvOS 17+
- visionOS 1+
- Swift 6.0

## Common Patterns

### Passing Data Between Screens

Use associated values in route cases:

```swift
enum AppRoute: Routable {
    case list
    case detail(item: Item)
    case edit(item: Item, onSave: () -> Void)  // Won't work - closures aren't Hashable
}

// For callbacks, use dismiss handlers instead:
router.sheet(.edit(item: item)) {
    // This runs after dismissal
    reloadData()
}
```

### Conditional Navigation

```swift
func handleDeepLink(_ url: URL) {
    if let itemId = parseItemId(from: url) {
        router.popToRoot()
        router.push(.detail(id: itemId))
    }
}
```

### Switching Root Route

For flows like login -> main app:

```swift
func completeLogin() {
    router.switchRoot(.mainApp)  // Clears stack and changes root
}
```

### Analytics Integration

```swift
RouterView(root: AppRoute.home) { screenName in
    Analytics.log(event: "screen_view", params: ["screen": screenName])
}
```

## Complete Example

```swift
import BigTime
import SwiftUI

@MainActor
enum AppRoute: Routable {
    case home
    case itemList
    case itemDetail(id: String)
    case settings
    case about

    var id: String {
        switch self {
        case .home: "home"
        case .itemList: "item-list"
        case .itemDetail(let id): "item-\(id)"
        case .settings: "settings"
        case .about: "about"
        }
    }

    var description: String {
        switch self {
        case .home: "Home"
        case .itemList: "Item List"
        case .itemDetail(let id): "Item Detail (\(id))"
        case .settings: "Settings"
        case .about: "About"
        }
    }

    var body: some View {
        switch self {
        case .home: HomeView()
        case .itemList: ItemListView()
        case .itemDetail(let id): ItemDetailView(itemId: id)
        case .settings: SettingsView()
        case .about: AboutView()
        }
    }
}

struct HomeView: View {
    @Environment(Router<AppRoute>.self) var router

    var body: some View {
        VStack(spacing: 20) {
            Button("View Items") {
                router.push(.itemList)
            }

            Button("Settings") {
                router.sheet(.settings, detents: [.medium, .large])
            }
        }
        .navigationTitle("Home")
    }
}

struct ItemListView: View {
    @Environment(Router<AppRoute>.self) var router
    let items = ["item-1", "item-2", "item-3"]

    var body: some View {
        List(items, id: \.self) { itemId in
            Button(itemId) {
                router.push(.itemDetail(id: itemId))
            }
        }
        .navigationTitle("Items")
    }
}

struct ItemDetailView: View {
    @Environment(Router<AppRoute>.self) var router
    let itemId: String

    var body: some View {
        VStack {
            Text("Item: \(itemId)")

            Button("Back to List") {
                router.pop()
            }

            Button("Back to Home") {
                router.popToRoot()
            }
        }
        .navigationTitle("Detail")
    }
}

struct SettingsView: View {
    @Environment(Router<AppRoute>.self) var router

    var body: some View {
        List {
            Button("About") {
                // Opens child sheet
                router.sheet(.about)
            }

            Button("Done") {
                router.dismissSheet()
            }
        }
        .navigationTitle("Settings")
    }
}

struct AboutView: View {
    @Environment(Router<AppRoute>.self) var router

    var body: some View {
        VStack {
            Text("BigTime Navigation Framework")
            Button("Close All") {
                router.dismissAllSheets()
            }
        }
        .navigationTitle("About")
    }
}

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            RouterView(root: AppRoute.home)
        }
    }
}
```

## Summary

1. Define routes as a `@MainActor enum` conforming to `Routable`
2. The enum IS the view - implement `body` to return the appropriate view
3. Wrap your app in `RouterView(root:)`
4. Access router via `@Environment(Router<YourRoute>.self)`
5. Use `push()`, `pop()`, `popToRoot()`, `switchRoot()` for stack navigation
6. Use `sheet()`, `fullScreenCover()` for modal presentation
7. Sheets automatically support hierarchy - just call `sheet()` from within a sheet
8. Use `router.universalOverlay()` for overlays tied to a router
9. Use `tabRouter.universalOverlay()` for overlays that persist across tabs
10. For tabs, use `TabRoutable` + `TabRouterView`

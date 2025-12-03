# BigTime

**Type-safe, protocol-driven navigation framework for SwiftUI apps**

BigTime is a reusable Swift Package that provides a robust navigation system for SwiftUI applications. It supports push navigation, sheet presentations, full-screen covers, and tab-based navigation with independent stacks per tab.

## Features

- ✅ **Type-safe routing** using protocol-based enums
- ✅ **Push navigation** with NavigationStack
- ✅ **Sheet presentations** with customizable detents and drag indicators
- ✅ **Full-screen covers** for immersive experiences
- ✅ **Tab-based navigation** with isolated stacks per tab
- ✅ **Screen view tracking** with optional callbacks
- ✅ **Dismiss handlers** for post-navigation actions
- ✅ **Built-in logging** using OSLog
- ✅ **Swift 6.0** with full concurrency support

## Installation

### Swift Package Manager

Add BigTime to your project via Xcode:

1. File → Add Package Dependencies...
2. Enter the repository URL
3. Select the version/branch
4. Add to your target

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/br3akzero/BigTime.git", from: "1.0.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: ["BigTime"]
    )
]
```

## Quick Start

### 1. Define Your Route Enum

Create a `Route` enum that conforms to `Routable`:

```swift
import BigTime
import SwiftUI

enum Route: Routable {
    case home
    case profile
    case settings
    case detail(id: String)
}

// MARK: - Hashable
extension Route: Hashable {
    static func == (lhs: Route, rhs: Route) -> Bool {
        switch (lhs, rhs) {
        case (.home, .home), (.profile, .profile), (.settings, .settings):
            return true
        case (.detail(let lID), .detail(let rID)):
            return lID == rID
        default:
            return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .home:
            hasher.combine("home")
        case .profile:
            hasher.combine("profile")
        case .settings:
            hasher.combine("settings")
        case .detail(let id):
            hasher.combine("detail")
            hasher.combine(id)
        }
    }
}

// MARK: - Identifiable
extension Route: Identifiable {
    var id: UUID { UUID() }
}

// MARK: - CustomStringConvertible
extension Route: CustomStringConvertible {
    var description: String {
        switch self {
        case .home: return "Home"
        case .profile: return "Profile"
        case .settings: return "Settings"
        case .detail(let id): return "Detail(\(id))"
        }
    }
}

// MARK: - View
extension Route: View {
    var body: some View {
        switch self {
        case .home:
            HomeScreen()
        case .profile:
            ProfileScreen()
        case .settings:
            SettingsScreen()
        case .detail(let id):
            DetailScreen(id: id)
        }
    }
}
```

### 2. Use RouterView in Your App

```swift
import BigTime
import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            RouterView<Route>(root: .home)
        }
    }
}
```

### 3. Navigate in Your Views

```swift
import BigTime
import SwiftUI

struct HomeScreen: View {
    @Environment(Router<Route>.self) private var router

    var body: some View {
        VStack {
            Button("Go to Profile") {
                router.push(.profile)
            }

            Button("Show Settings Sheet") {
                router.sheet(.settings)
            }

            Button("Show Detail Full Screen") {
                router.fullScreenCover(.detail(id: "123"))
            }
        }
    }
}
```

## Tab-Based Navigation

### 1. Define Your TabRoute Enum

```swift
import BigTime
import SwiftUI

enum TabRoute: TabRoutable {
    case home
    case search
    case profile

    var rootRoute: Route {
        switch self {
        case .home: return .home
        case .search: return .search
        case .profile: return .profile
        }
    }

    var title: String {
        switch self {
        case .home: return "Home"
        case .search: return "Search"
        case .profile: return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .search: return "magnifyingglass"
        case .profile: return "person.circle"
        }
    }
}

// MARK: - Hashable, Identifiable, CaseIterable
extension TabRoute: Hashable, Identifiable, CaseIterable {
    var id: String { title }

    static var allCases: [TabRoute] {
        [.home, .search, .profile]
    }
}

// MARK: - CustomStringConvertible
extension TabRoute: CustomStringConvertible {
    var description: String { title }
}
```

### 2. Use TabRouterView in Your App

```swift
import BigTime
import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            TabRouterView<TabRoute>()
        }
    }
}
```

### 3. Navigate Between Tabs

```swift
struct HomeScreen: View {
    @Environment(TabRouter<TabRoute>.self) private var tabRouter
    @Environment(Router<Route>.self) private var router

    var body: some View {
        VStack {
            Button("Switch to Search Tab") {
                tabRouter.switchTab(to: .search)
            }

            Button("Push Detail in Current Tab") {
                router.push(.detail(id: "abc"))
            }
        }
    }
}
```

## Advanced Features

### Screen View Tracking

Track screen views for analytics:

```swift
RouterView(root: .home) { screenName in
    // Log to your analytics service
    Analytics.track(screen: screenName)
}
```

### Dismiss Handlers

Execute code after modal dismissal:

```swift
router.sheet(.settings) {
    // Refresh data after settings are dismissed
    Task { await loadUserData() }
}
```

### Custom Sheet Detents

Control sheet presentation sizes:

```swift
router.sheet(
    .settings,
    detents: [.medium, .large],
    dragIndicator: .visible
)
```

### Custom Logging Subsystem

Provide a custom subsystem for logging:

```swift
let router = Router(
    root: .home,
    subsystem: "com.myapp.navigation"
)
```

## API Reference

### Protocols

#### `Routable`
Protocol that your Route enum must conform to:
- `Hashable` - For NavigationStack path
- `Sendable` - For concurrency safety
- `Identifiable` - For SwiftUI list/forEach
- `CustomStringConvertible` - For logging
- `View` - To render the route

#### `TabRoutable`
Protocol that your TabRoute enum must conform to:
- `Hashable` - For tab selection
- `Sendable` - For concurrency safety
- `Identifiable` - For SwiftUI tabs
- `CustomStringConvertible` - For logging
- `CaseIterable` - To enumerate all tabs
- `associatedtype RouteType: Routable` - The route type for this tab

### Classes

#### `Router<Route: Routable>`
Observable router managing navigation state:

**Properties:**
- `routes: [Route]` - Navigation stack
- `rootRoute: Route` - Base route
- `sheetRoute: Route?` - Current sheet
- `fullScreenCoverRoute: Route?` - Current cover

**Methods:**
- `push(_ route: Route)` - Push onto stack
- `pop()` - Pop from stack
- `popToRoot()` - Clear stack
- `switchRoot(_ root: Route)` - Change root route
- `sheet(_ route: Route, detents:dragIndicator:onDismiss:)` - Present sheet
- `fullScreenCover(_ route: Route, onDismiss:)` - Present cover
- `dismissSheet()` - Dismiss sheet
- `dismissFullScreenCover()` - Dismiss cover

#### `TabRouter<TabRoute: TabRoutable>`
Observable router managing tab navigation:

**Properties:**
- `selectedTab: TabRoute` - Current tab
- `routers: [TabRoute: Router<TabRoute.RouteType>]` - Per-tab routers
- `currentRouter: Router<TabRoute.RouteType>` - Router for selected tab

**Methods:**
- `router(for tab: TabRoute)` - Get router for specific tab
- `switchTab(to tab: TabRoute)` - Switch to tab

### Views

#### `RouterView<Route: Routable>`
SwiftUI view managing navigation:

**Initializers:**
- `init(router: Router<Route>, onScreenView:)` - Use existing router
- `init(root: Route, subsystem:onScreenView:)` - Create new router

#### `TabRouterView<TabRoute: TabRoutable>`
SwiftUI view managing tab navigation:

**Initializers:**
- `init(tabRouter: TabRouter<TabRoute>, onScreenView:)` - Use existing tab router
- `init(selectedTab:subsystem:onScreenView:)` - Create new tab router

## Requirements

- iOS 18.0+ / macOS 15.0+ / watchOS 11.0+ / tvOS 18.0+ / visionOS 2.0+
- Swift 6.0+
- Xcode 16.0+

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Support

- [Documentation](https://github.com/br3akzero/BigTime#readme)
- [Issue Tracker](https://github.com/br3akzero/BigTime/issues)
- [Discussions](https://github.com/br3akzero/BigTime/discussions)

## Author

Created by [@br3akzero](https://github.com/br3akzero)

## Acknowledgments

Built with using Swift 6.0 and SwiftUI

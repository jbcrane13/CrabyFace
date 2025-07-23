
# Claude Development Guidelines - iOS/iPadOS TDD-MVVM-SwiftUI
## Memory usage

Follow these steps for each interaction:

1. User Identification:
   - You should assume that you are interacting with default_user
   - If you have not identified default_user, proactively try to do so.

2. Memory Retrieval:
   - Always begin your chat by saying only "Remembering..." and retrieve all relevant information from your knowledge graph
   - Always refer to your knowledge graph as your "memory"

3. Memory
   - While conversing with the user, be attentive to any new information that falls into these categories:
     a) Basic Identity (age, gender, location, job title, education level, etc.)
     b) Behaviors (interests, habits, etc.)
     c) Preferences (communication style, preferred language, etc.)
     d) Goals (goals, targets, aspirations, etc.)
     e) Relationships (personal and professional relationships up to 3 degrees of separation)

4. Memory Update:
   - If any new information was gathered during the interaction, update your memory as follows:
     a) Create entities for recurring organizations, people, and significant events
     b) Connect them to the current entities using relations
     c) Store facts about them as observations
     
## Project Architecture Mandate

This project follows:
- **Test-Driven Development (TDD)** - No production code without failing tests
- **MVVM Architecture** - Strict separation of Model, View, and ViewModel
- **SwiftUI** - Modern declarative UI framework for iOS/iPadOS

## MVVM-TDD Workflow

### Testing Order (ALWAYS follow this sequence):
1. **Model Tests** → Model Implementation
2. **ViewModel Tests** → ViewModel Implementation  
3. **View Tests** → View Implementation
4. **Integration Tests** → Full feature validation

## MVVM Architecture Rules

### Model Layer
- Pure Swift structs/classes
- No SwiftUI or Combine imports
- Responsible for data structures and business logic
- Must be 100% testable without UI

### ViewModel Layer
- ObservableObject classes with @Published properties
- Contains all presentation logic
- No SwiftUI View imports (only Combine/Foundation)
- Handles all business logic and state management
- Must be testable in isolation from Views

### View Layer
- SwiftUI Views only
- No business logic - only UI binding and presentation
- Binds to ViewModel via @StateObject/@ObservedObject
- All logic delegated to ViewModel

## TDD Implementation for MVVM

### 1. Model TDD Cycle

```swift
// STEP 1: Write failing Model test
func test_user_initialization_shouldSetAllProperties() {
    // RED: This fails because User doesn't exist
    let user = User(
        id: UUID(),
        email: "test@example.com",
        name: "Test User",
        role: .standard
    )
    
    XCTAssertEqual(user.email, "test@example.com")
    XCTAssertEqual(user.name, "Test User")
    XCTAssertEqual(user.role, .standard)
}

// STEP 2: Implement minimal Model
struct User: Identifiable, Equatable {
    let id: UUID
    let email: String
    let name: String
    let role: UserRole
}

// STEP 3: Refactor if needed (keeping tests green)
```

### 2. ViewModel TDD Cycle

```swift
// STEP 1: Write failing ViewModel test
class LoginViewModelTests: XCTestCase {
    func test_login_withValidCredentials_shouldUpdateStateToAuthenticated() {
        // RED: LoginViewModel doesn't exist
        let mockAuth = MockAuthService()
        let viewModel = LoginViewModel(authService: mockAuth)
        
        mockAuth.mockResult = .success(User.mock)
        
        viewModel.login(email: "test@example.com", password: "password")
        
        XCTAssertEqual(viewModel.state, .authenticated)
        XCTAssertNotNil(viewModel.currentUser)
    }
    
    func test_login_withInvalidCredentials_shouldShowError() {
        let mockAuth = MockAuthService()
        let viewModel = LoginViewModel(authService: mockAuth)
        
        mockAuth.mockResult = .failure(.invalidCredentials)
        
        viewModel.login(email: "wrong@example.com", password: "wrong")
        
        XCTAssertEqual(viewModel.state, .error("Invalid credentials"))
        XCTAssertNil(viewModel.currentUser)
    }
}

// STEP 2: Implement ViewModel to pass tests
@MainActor
class LoginViewModel: ObservableObject {
    @Published var state: ViewState = .idle
    @Published var currentUser: User?
    
    private let authService: AuthServiceProtocol
    
    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }
    
    func login(email: String, password: String) {
        Task {
            state = .loading
            do {
                let user = try await authService.login(email: email, password: password)
                currentUser = user
                state = .authenticated
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }
}
```

### 3. View TDD Cycle

```swift
// STEP 1: Write failing View test using ViewInspector
func test_loginView_whenFieldsEmpty_shouldDisableLoginButton() throws {
    // RED: LoginView doesn't exist
    let viewModel = LoginViewModel(authService: MockAuthService())
    let view = LoginView(viewModel: viewModel)
    
    let button = try view.inspect().find(button: "Login")
    XCTAssertTrue(try button.isDisabled())
}

func test_loginView_whenLoading_shouldShowProgressView() throws {
    let viewModel = LoginViewModel(authService: MockAuthService())
    viewModel.state = .loading
    let view = LoginView(viewModel: viewModel)
    
    XCTAssertNoThrow(try view.inspect().find(ViewType.ProgressView.self))
}

// STEP 2: Implement View to pass tests
struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel
    @State private var email = ""
    @State private var password = ""
    
    init(viewModel: LoginViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack {
            if viewModel.state == .loading {
                ProgressView()
            } else {
                TextField("Email", text: $email)
                SecureField("Password", text: $password)
                
                Button("Login") {
                    viewModel.login(email: email, password: password)
                }
                .disabled(email.isEmpty || password.isEmpty)
            }
        }
    }
}
```

## iOS/iPadOS Specific Testing Requirements

### Universal App Considerations
```swift
// Test for both iPhone and iPad layouts
func test_dashboardView_oniPad_shouldShowSplitView() throws {
    let view = DashboardView()
        .environment(\.horizontalSizeClass, .regular)
    
    XCTAssertNoThrow(try view.inspect().find(NavigationSplitView.self))
}

func test_dashboardView_oniPhone_shouldShowNavigationStack() throws {
    let view = DashboardView()
        .environment(\.horizontalSizeClass, .compact)
    
    XCTAssertNoThrow(try view.inspect().find(NavigationStack.self))
}
```

### iPadOS Features Testing
- **Multitasking**: Test multiple window scenarios
- **Drag & Drop**: Test drag and drop interactions
- **Keyboard Shortcuts**: Test keyboard command handling
- **Pencil Support**: Test pencil interactions if applicable
- **Split View**: Test master-detail navigation

## Required Test Coverage by MVVM Layer

### Model Layer (95%+ coverage)
- All initializers
- All computed properties
- All methods
- Codable conformance
- Equatable/Hashable implementations
- Validation logic

### ViewModel Layer (90%+ coverage)
- All @Published property changes
- All public methods
- All state transitions
- Error handling paths
- Async operations with proper expectations
- Combine pipeline logic

### View Layer (80%+ coverage)
- All user interactions
- All conditional rendering
- State-based UI changes
- Accessibility properties
- iPad vs iPhone layout differences
- Dark mode appearance

## MVVM-Specific Testing Patterns

### Dependency Injection for Testability
```swift
// ALWAYS use protocols for dependencies
protocol AuthServiceProtocol {
    func login(email: String, password: String) async throws -> User
}

// Mock for testing
class MockAuthService: AuthServiceProtocol {
    var mockResult: Result<User, AuthError>!
    
    func login(email: String, password: String) async throws -> User {
        switch mockResult {
        case .success(let user): return user
        case .failure(let error): throw error
        case .none: fatalError("Mock not configured")
        }
    }
}
```

### Testing @Published Properties
```swift
func test_viewModel_publishedPropertyChanges() {
    let expectation = expectation(description: "Published property updated")
    var cancellables = Set<AnyCancellable>()
    
    viewModel.$items
        .dropFirst() // Skip initial value
        .sink { items in
            XCTAssertEqual(items.count, 3)
            expectation.fulfill()
        }
        .store(in: &cancellables)
    
    viewModel.loadItems()
    wait(for: [expectation], timeout: 1.0)
}
```

### Testing View-ViewModel Binding
```swift
func test_view_bindsToViewModelState() throws {
    let viewModel = ItemListViewModel()
    let view = ItemListView(viewModel: viewModel)
    
    // Verify initial state
    XCTAssertTrue(try view.inspect().find(text: "No items").exists())
    
    // Update ViewModel
    viewModel.items = [Item(name: "Test")]
    
    // Verify View updates
    XCTAssertThrows(try view.inspect().find(text: "No items").exists())
    XCTAssertNoThrow(try view.inspect().find(text: "Test"))
}
```

## File Organization for MVVM-TDD

```
YourApp/
├── Models/
│   ├── User.swift
│   └── UserTests.swift
├── ViewModels/
│   ├── LoginViewModel.swift
│   └── LoginViewModelTests.swift
├── Views/
│   ├── LoginView.swift
│   └── LoginViewTests.swift
├── Services/
│   ├── AuthService.swift
│   ├── AuthServiceProtocol.swift
│   └── MockAuthService.swift
└── IntegrationTests/
    └── LoginFlowTests.swift
```

## TDD-MVVM Checklist

Before submitting ANY code:

### Model Checklist
- [ ] Model test written first and failing
- [ ] Model implementation minimal to pass test
- [ ] Model has no UI dependencies
- [ ] Model is Equatable/Codable if needed
- [ ] All Model business logic tested

### ViewModel Checklist
- [ ] ViewModel test written first and failing
- [ ] Dependencies injected via protocols
- [ ] All @Published properties have tests
- [ ] Async operations tested with expectations
- [ ] Error states tested
- [ ] No SwiftUI imports in ViewModel

### View Checklist
- [ ] View test written first using ViewInspector
- [ ] View contains no business logic
- [ ] All UI states tested
- [ ] iPad and iPhone layouts tested
- [ ] Accessibility tested
- [ ] Dark mode tested

### Integration Checklist
- [ ] Full user flow tested
- [ ] Navigation tested
- [ ] Data flow between screens tested
- [ ] State persistence tested

## Common MVVM-TDD Violations

### ❌ NEVER DO:
- Put business logic in Views
- Import SwiftUI in ViewModels
- Create ViewModels without protocol-based dependencies
- Skip testing "simple" ViewModels
- Test private ViewModel methods
- Create tight coupling between layers
- Write integration tests before unit tests

### ✅ ALWAYS DO:
- Test ViewModels in complete isolation
- Use protocols for all dependencies
- Test public interfaces only
- Mock all external services
- Test each MVVM layer separately
- Write focused, single-behavior tests
- Maintain clear separation of concerns

## Example Full TDD-MVVM Feature Flow

```swift
// 1. Start with Model Test
func test_todoItem_toggleComplete_shouldInvertStatus() {
    var item = TodoItem(title: "Test", isComplete: false)
    item.toggleComplete()
    XCTAssertTrue(item.isComplete)
}

// 2. Implement Model
struct TodoItem: Identifiable {
    let id = UUID()
    let title: String
    var isComplete: Bool
    
    mutating func toggleComplete() {
        isComplete.toggle()
    }
}

// 3. Write ViewModel Test
func test_todoViewModel_toggleItem_shouldUpdateItem() {
    let viewModel = TodoViewModel()
    let item = TodoItem(title: "Test", isComplete: false)
    viewModel.items = [item]
    
    viewModel.toggleItem(item)
    
    XCTAssertTrue(viewModel.items[0].isComplete)
}

// 4. Implement ViewModel
class TodoViewModel: ObservableObject {
    @Published var items: [TodoItem] = []
    
    func toggleItem(_ item: TodoItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].toggleComplete()
        }
    }
}

// 5. Write View Test
func test_todoView_tapCheckmark_shouldCallToggle() throws {
    let viewModel = TodoViewModel()
    let item = TodoItem(title: "Test", isComplete: false)
    viewModel.items = [item]
    
    let view = TodoListView(viewModel: viewModel)
    let button = try view.inspect().find(button: "Toggle")
    
    try button.tap()
    
    XCTAssertTrue(viewModel.items[0].isComplete)
}

// 6. Implement View
struct TodoListView: View {
    @StateObject var viewModel: TodoViewModel
    
    var body: some View {
        List(viewModel.items) { item in
            HStack {
                Text(item.title)
                Spacer()
                Button("Toggle") {
                    viewModel.toggleItem(item)
                }
            }
        }
    }
}
```

## Performance Testing for iPad

```swift
// Test large datasets for iPad
func test_viewModel_largeDataset_shouldPerformEfficiently() {
    let viewModel = ItemListViewModel()
    let items = (0..<10000).map { Item(id: $0) }
    
    measure {
        viewModel.items = items
        _ = viewModel.filteredItems(matching: "500")
    }
}
```

## Build and Runtime Verification Process

### CRITICAL: Verification Requirements

When asked to fix build errors or ensure the app runs, you MUST complete ALL of the following steps before reporting success:

1. **Clean Build Verification**
   ```bash
   # Clean build folder
   xcodebuild clean -project JubileeMobileBay.xcodeproj -scheme JubileeMobileBay
   
   # Build for specific simulator
   xcodebuild -project JubileeMobileBay.xcodeproj \
       -scheme JubileeMobileBay \
       -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' \
       build
   ```

2. **Simulator Installation**
   ```bash
   # Boot simulator (if not already running)
   xcrun simctl boot "iPhone 16 Pro"
   
   # Install the app
   xcrun simctl install "iPhone 16 Pro" \
       /path/to/DerivedData/.../JubileeMobileBay.app
   ```

3. **App Launch Verification**
   ```bash
   # Launch the app and get process ID
   xcrun simctl launch "iPhone 16 Pro" com.jubileemobilebay.app
   ```

4. **CRITICAL: Simulator Log Verification**
   ```bash
   # ALWAYS check simulator logs for crashes after launch
   sleep 3 && xcrun simctl spawn "iPhone 16 Pro" log show \
       --predicate 'process CONTAINS "JubileeMobileBay"' \
       --last 1m 2>/dev/null | tail -10
   
   # Check specifically for fatal errors
   xcrun simctl spawn "iPhone 16 Pro" log show \
       --predicate 'process CONTAINS "JubileeMobileBay" AND eventMessage CONTAINS "Fatal"' \
       --last 2m 2>/dev/null
   ```

5. **Functional Verification Checklist**
   - [ ] Build completes without errors
   - [ ] App installs on simulator
   - [ ] App launches without crashing (process ID returned)
   - [ ] **SIMULATOR LOGS CHECKED FOR CRASHES** ⚠️ CRITICAL
   - [ ] No "Fatal error" messages in logs
   - [ ] Main screen appears
   - [ ] Navigation between screens works
   - [ ] Dashboard displays with data (mock or real)
   - [ ] No runtime errors in console

### CRITICAL: False Success Prevention

**DO NOT** report success based solely on:**
- `BUILD SUCCEEDED` message
- Xcode showing no errors
- Process ID returned from launch command ⚠️ **THIS IS NOT SUFFICIENT**
- Partial completion of tasks

**ALWAYS verify:**
- **Check simulator logs for crash messages** ⚠️ **MOST IMPORTANT**
- The app actually launches AND stays running
- Core functionality works
- Data loads as expected

### Common iOS Simulator Launch Issues

**CloudKit/Core Data Issues:**
- Unique constraints not supported in CloudKit
- Non-optional attributes must have default values
- Check logs for "Core Data failed to load" messages

**Memory/Resource Issues:**
- Large datasets causing crashes
- Background task violations
- Check for "Memory pressure" warnings

### Mock Data for Development

When real services fail, implement mock data providers:

```swift
#if DEBUG
// Use mock data providers
let provider = DevelopmentDataProvider.shared
_viewModel = StateObject(wrappedValue: DashboardViewModel(
    weatherAPI: provider.weatherAPI,
    marineAPI: provider.marineAPI
))
#else
// Production initialization
#endif
```

---

**Remember**: Every feature starts with a failing test. MVVM layers must remain decoupled. SwiftUI Views must be dumb. Build verification must be complete. This is non-negotiable for maintainable iOS/iPadOS applications.
```


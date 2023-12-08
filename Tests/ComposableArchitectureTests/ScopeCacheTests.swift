@_spi(Internals) import ComposableArchitecture
import XCTest

@MainActor
final class ScopeCacheTests: BaseTCATestCase {
  @available(*, deprecated)
  func testOptionalScope_UncachedStore() {
    #if DEBUG
      let store = StoreOf<Feature>(initialState: Feature.State(child: Feature.State())) {
        // TODO: Investigate cancellation cancellables leak
        // Feature()
      }

      XCTExpectFailure {
        _ =
          store
          .scope(state: { $0 }, action: { $0 })
          .scope(state: \.child, action: \.child.presented)?
          .send(.show)
      } issueMatcher: {
        $0.compactDescription == """
          Scoping from uncached StoreOf<Feature> is not compatible with observation. Ensure that all \
          parent store scoping operations take key paths and case key paths instead of transform \
          functions, which have been deprecated.
          """
      }
      store.send(.child(.dismiss))
    #endif
  }

  func testOptionalScope_CachedStore() {
    #if DEBUG
      let store = StoreOf<Feature>(initialState: Feature.State(child: Feature.State())) {
        // TODO: Investigate cancellation cancellables leak
        // Feature()
      }
      store
        .scope(state: \.self, action: \.self)
        .scope(state: \.child, action: \.child.presented)?
        .send(.show)
    #endif
  }

  func testOptionalScope_StoreIfLet() {
    #if DEBUG
      let store = StoreOf<Feature>(initialState: Feature.State(child: Feature.State())) {
        Feature()
      }
      let cancellable =
        store
        .scope(state: \.child, action: \.child.presented)
        .ifLet { store in
          store.scope(state: \.child, action: \.child.presented)?.send(.show)
        }
      _ = cancellable
    #endif
  }

  @available(*, deprecated)
  func testOptionalScope_StoreIfLet_UncachedStore() {
    #if DEBUG
      let store = StoreOf<Feature>(initialState: Feature.State(child: Feature.State())) {
        // TODO: Investigate cancellation cancellables leak
        // Feature()
      }
      XCTExpectFailure {
        let cancellable =
          store
          .scope(state: { $0 }, action: { $0 })
          .ifLet { store in
            store.scope(state: \.child, action: \.child.presented)?.send(.show)
          }
        _ = cancellable
      } issueMatcher: {
        $0.compactDescription == """
          Scoping from uncached StoreOf<Feature> is not compatible with observation. Ensure that all \
          parent store scoping operations take key paths and case key paths instead of transform \
          functions, which have been deprecated.
          """
      }
    #endif
  }

  func testIdentifiedArrayScope_CachedStore() {
    #if DEBUG
      let store = StoreOf<Feature>(initialState: Feature.State(rows: [Feature.State()])) {
        // TODO: Investigate cancellation cancellables leak
        // Feature()
      }

      let rowsStore = Array(
        store
          .scope(state: \.self, action: \.self)
          .scope(state: \.rows, action: \.rows)
      )
      rowsStore[0].send(.show)
    #endif
  }

  @available(*, deprecated)
  func testIdentifiedArrayScope_UncachedStore() {
    #if DEBUG
      let store = StoreOf<Feature>(initialState: Feature.State(rows: [Feature.State()])) {
        Feature()
      }
      XCTExpectFailure {
        _ = Array(
          store
            .scope(state: { $0 }, action: { $0 })
            .scope(state: \.rows, action: \.rows)
        )
      } issueMatcher: {
        $0.compactDescription == """
          Scoping from uncached StoreOf<Feature> is not compatible with observation. Ensure that all \
          parent store scoping operations take key paths and case key paths instead of transform \
          functions, which have been deprecated.
          """
      }
    #endif
  }

  func testBasics() {
    let store = Store(initialState: Feature.State(child: Feature.State())) {
      Feature()
    }
    let childStore: Store = store.scope(state: \.child, action: \.child)
    let unwrappedChildStore = childStore.scope(
      state: { $0! },
      id: childStore.id(state: \.!, action: \.self),
      action: { $0 },
      isInvalid: { $0 == nil },
      removeDuplicates: nil
    )
    unwrappedChildStore.send(.dismiss)
    XCTAssertEqual(store.stateSubject.value.child, nil)
  }
}

@Reducer
private struct Feature {
  @ObservableState
  struct State: Identifiable, Equatable {
    let id = UUID()
    @Presents var child: Feature.State?
    var rows: IdentifiedArrayOf<Feature.State> = []
  }
  indirect enum Action {
    case child(PresentationAction<Feature.Action>)
    case dismiss
    case rows(IdentifiedActionOf<Feature>)
    case show
  }
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .child(.presented(.dismiss)):
        state.child = nil
        return .none
      case .child:
        return .none
      case .dismiss:
        return .none
      case .rows:
        return .none
      case .show:
        state.child = Feature.State()
        return .none
      }
    }
    .ifLet(\.$child, action: \.child) {
      Feature()
    }
    .forEach(\.rows, action: \.rows) {
      Feature()
    }
  }
}

import Combine
import XCTest

@testable import ComposableArchitecture

final class IfLetUIKitTests: XCTestCase {
	
	var cancellables: Set<AnyCancellable> = []

  func testIfLetAfterScope() {
		struct AppState {
			var count: Int?
		}

		let appReducer = Reducer<AppState, Int?, Void> { state, action, _ in
				state.count = action
				return .none
		}
		
		let parentStore = Store(initialState: AppState(), reducer: appReducer, environment: ())
		
		// NB: This test needs to hold a strong reference to the emitted stores
		var outputs: [Store<Int, Int?>?] = []
		
		parentStore
			.scope(state: \.count)
			.ifLet(
				then: { store in
					outputs.append(store)
				},
				else: {
					outputs.append(nil)
			})
			.store(in: &self.cancellables)
			
		XCTAssertEqual(outputs.map { $0?.state }, [nil])
		
		parentStore.send(1)
		XCTAssertEqual(outputs.map { $0?.state }, [nil, 1])

		parentStore.send(nil)
		XCTAssertEqual(outputs.map { $0?.state }, [nil, 1, nil])
  }
}

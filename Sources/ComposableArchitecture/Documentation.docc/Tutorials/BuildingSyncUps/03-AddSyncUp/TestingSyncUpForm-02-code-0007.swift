
import ComposableArchitecture
import SyncUps
import XCTest

class SyncUpFormTests: XCTestCase {
  func testAddAttendee() {
    let store = TestStore(
      initialState: SyncUpForm.State(
        syncUp: SyncUp(id: SyncUp.ID())
      )
    ) {
      SyncUpForm()
    } withDependencies: {
      $0.uuid = .incrementing
    }

    await store.send(.addAttendeeButtonTapped) {
      state.focus = .attendee(Attendee.ID(UUID()))
      state.syncUp.attendees.append(Attendee(id: Attendee.ID(UUID())))
    }
  }

  func testRemoveFocusedAttendee() {
    let attendee1 = Attendee(id: Attendee.ID())
    let attendee2 = Attendee(id: Attendee.ID())
    let store = TestStore(
      initialState: SyncUpForm.State(
        focus: .attendee(attendee1.id),
        syncUp: SyncUp(
          id: SyncUp.ID(),
          attendees: [attendee1, attendee2]
        )
      )
    ) {
      SyncUpForm()
    }

    await store.send(.onDeleteAttendees([0])) {
      state.focus = .attendee(attendee2.id)
      state.attendees = [attendee2]
    }
  }

  func testRemoveAttendee() {
    let store = TestStore(
      initialState: SyncUpForm.State(
        syncUp: SyncUp(
          id: SyncUp.ID(),
          attendees: [
            Attendee(id: Attendee.ID())
          ]
        )
      )
    ) {
      SyncUpForm()
    }

    await store.send(.onDeleteAttendees([0])) {
      state.syncUp.attendees = []
    }
  }
}

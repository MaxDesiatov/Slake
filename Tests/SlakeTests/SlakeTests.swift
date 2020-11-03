import Combine
import CombineExpectations
import Slake
import XCTest

struct A: Query {
  func task(for runner: TaskRunner) -> AnyPublisher<Int, Never> {
    Just(10).eraseToAnyPublisher()
  }
}

struct B: Query {
  func task(for runner: TaskRunner) -> AnyPublisher<Int, Never> {
    runner(A()).map { $0 + 20 }.eraseToAnyPublisher()
  }
}

struct C: Query {
  func task(for runner: TaskRunner) -> AnyPublisher<Int, Never> {
    runner(A()).map { $0 + 30 }.eraseToAnyPublisher()
  }
}

struct D: Query {
  func task(for runner: TaskRunner) -> AnyPublisher<Int, Never> {
    runner(B())
      .zip(runner(C()))
      .map { $0.0 + $0.1 }
      .eraseToAnyPublisher()
  }
}

final class SlakeTests: XCTestCase {
  func testSimpleQuery() throws {
    let runner = TaskRunner(cache: .inMemory)

    let publisher1 = runner(D())
    let recorder1 = publisher1.record()
    let elements1 = try wait(for: recorder1.elements, timeout: 0.1)

    XCTAssertEqual(elements1, [70])

    print("First execution complete")

    let publisher2 = runner(D())
    let recorder2 = publisher2.record()
    let elements2 = try wait(for: recorder2.elements, timeout: 0.1)
    XCTAssertEqual(elements2, [70])
  }
}

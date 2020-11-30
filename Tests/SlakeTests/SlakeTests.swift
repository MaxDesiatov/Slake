import Combine
import CombineExpectations
import Slake
import XCTest

struct A: Query {
  func task(for runner: TaskRunner) -> Task<Int, Never> {
    Just(10).eraseToTask()
  }
}

struct B: Query {
  func task(for runner: TaskRunner) -> Task<Int, Never> {
    runner.query(A()).map { $0 + 20 }.eraseToTask()
  }
}

struct C: Query {
  func task(for runner: TaskRunner) -> Task<Int, Never> {
    runner.query(A()).map { $0 + 30 }.eraseToTask()
  }
}

struct D: Query {
  func task(for runner: TaskRunner) -> Task<Int, Never> {
    runner.query(B())
      .zip(runner.query(C()))
      .map { $0.0 + $0.1 }
      .eraseToTask()
  }
}

final class SlakeTests: XCTestCase {
  func testSimpleQuery() throws {
    let runner = TaskRunner(resultsCache: .inMemory)

    let publisher1 = runner.query(D())
    let recorder1 = publisher1.record()
    let elements1 = try wait(for: recorder1.elements, timeout: 0.1)

    XCTAssertEqual(elements1, [70])

    print("First execution complete")

    let publisher2 = runner.query(D())
    let recorder2 = publisher2.record()
    let elements2 = try wait(for: recorder2.elements, timeout: 0.1)
    XCTAssertEqual(elements2, [70])
  }
}

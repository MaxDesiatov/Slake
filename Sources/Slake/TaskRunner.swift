import Combine
import Dispatch

public protocol Query: Hashable, Codable {
  associatedtype Output
  associatedtype Failure: Error

  func task(for runner: TaskRunner) -> Task<Output, Failure>
}

public final class Task<Output, Failure: Error> {
  init(publisher: AnyPublisher<Output, Failure>) {
    self.publisher = publisher
  }

  let publisher: AnyPublisher<Output, Failure>
}

public extension Publisher {
  func eraseToTask() -> Task<Output, Failure> {
    .init(publisher: eraseToAnyPublisher())
  }
}

public final class Cache {
  init(
    getter: @escaping (AnyHashable) -> Any?,
    setter: @escaping (AnyHashable, Any?) -> (),
    queue: DispatchQueue
  ) {
    self.getter = getter
    self.setter = setter
    self.queue = queue
  }

  let getter: (AnyHashable) -> Any?
  let setter: (AnyHashable, Any?) -> ()
  let queue: DispatchQueue

  subscript(_ key: AnyHashable) -> Any? {
    set { setter(key, newValue) }
    get { getter(key) }
  }

  public static var inMemory: Self {
    var cache = [AnyHashable: Any]()

    return .init(getter: { cache[$0] }, setter: { cache[$0] = $1 }, queue: DispatchQueue.main)
  }
}

public final class TaskRunner {
  private var resultsCache: Cache
  private var inProgress = [AnyHashable: Any]()

  public init(resultsCache: Cache) {
    self.resultsCache = resultsCache
  }

  public func callAsFunction<Q: Query>(_ query: Q) -> AnyPublisher<Q.Output, Q.Failure> {
    print("Running \(query)")

    if let inProgressTask = inProgress[query] as? AnyPublisher<Q.Output, Q.Failure> {
      print("Found in progress task for \(query)")
      return inProgressTask
    }

    if let cached = resultsCache[query] as? Q.Output {
      print("Found cached output for \(query)")
      return Just(cached).setFailureType(to: Q.Failure.self).eraseToAnyPublisher()
    }

    let task = query.task(for: self)
    print("Storing a reference to \(query) as in progress")
    inProgress[query] = task

    return task
      .publisher
      .receive(on: resultsCache.queue)
      .handleEvents(
        receiveOutput: {
          print("caching result \($0) for query \(query)")
          self.resultsCache[query] = $0
        },
        receiveCompletion: { _ in
          self.inProgress[query] = nil
        }
      ).eraseToAnyPublisher()
  }
}

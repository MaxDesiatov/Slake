//
//  Created by Max Desiatov on 24/11/2020.
//

import Combine
import Dispatch
import TSCBasic

private let fsQueue = DispatchQueue.global(qos: .utility)

struct FileDependency: Query {
  let pathPatterns: [String]

  func task(for runner: TaskRunner) -> Task<AbsolutePath, Error> {
    Empty().eraseToTask()
  }
}

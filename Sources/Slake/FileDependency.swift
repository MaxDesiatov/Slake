//
//  Created by Max Desiatov on 24/11/2020.
//

import Combine
import Dispatch
import TSCBasic

private let fsQueue = DispatchQueue.global(qos: .utility)

struct FileDependency: Query {
  let files: [AbsolutePath]

  func task(for runner: TaskRunner) -> Task<AbsolutePath, Error> {
    Empty().eraseToTask()
  }
}

struct CObjectFile: Query {
  let sourceFile: AbsolutePath

  func task(for runner: TaskRunner) -> Task<AbsolutePath, Error> {
    Empty().eraseToTask()
  }
}

struct LinkExecutable: Query {
  let objectFiles: [AbsolutePath]
  let executableFile: AbsolutePath

  func task(for runner: TaskRunner) -> Task<AbsolutePath, Error> {
    Empty().eraseToTask()
  }
}

struct BuildCExecutable: Query {
  let sourceFiles: [AbsolutePath]
  let executableFile: AbsolutePath
  let parallelJobs = 1

  func task(for runner: TaskRunner) -> Task<AbsolutePath, Error> {
    runner(FileDependency(files: sourceFiles))
      .flatMap(maxPublishers: .max(parallelJobs)) {
        runner(CObjectFile(sourceFile: $0))
      }
      .collect()
      .flatMap {
        runner(LinkExecutable(objectFiles: $0, executableFile: executableFile))
      }.eraseToTask()
  }
}

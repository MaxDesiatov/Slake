//
//  Created by Max Desiatov on 24/11/2020.
//

import Combine
import Dispatch
import TSCBasic

private let fsQueue = DispatchQueue.global(qos: .utility)

struct FileInfo: Hashable, Codable {
  let path: AbsolutePath
  let size: UInt64
  let hash: [UInt8]
}

struct CObjectFile: Query {
  let sourceFile: FileInfo

  func task(for runner: TaskRunner) -> Task<FileInfo, Error> {
    runner.fork("cc", "-c", sourceFile.path.pathString)
      .flatMap { _ in
        runner.fileInfo(
          sourceFile.path.parentDirectory.appending(
            component: "\(sourceFile.path.basenameWithoutExt).o"
          )
        )
      }.eraseToTask()
  }
}

struct LinkExecutable: Query {
  let objectFiles: [FileInfo]
  let executableFile: AbsolutePath

  func task(for runner: TaskRunner) -> Task<FileInfo, Error> {
    runner.fork(["ld"] + objectFiles.map(\.path.pathString))
      .flatMap { _ in
        runner.fileInfo(
          executableFile.parentDirectory.appending(
            component: executableFile.basenameWithoutExt
          )
        )
      }
      .eraseToTask()
  }
}

struct BuildCExecutable: Query {
  let sourceFiles: [AbsolutePath]
  let executableFile: AbsolutePath

  func task(for runner: TaskRunner) -> Task<AbsolutePath, Error> {
    runner.fileInfo(sourceFiles)
      .flatMap(maxPublishers: .unlimited) {
        runner.query(CObjectFile(sourceFile: $0))
      }
      .collect()
      .flatMap {
        runner.query(LinkExecutable(objectFiles: $0, executableFile: executableFile))
      }
      .map(\.path)
      .eraseToTask()
  }
}

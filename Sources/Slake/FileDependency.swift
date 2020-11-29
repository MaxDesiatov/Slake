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

func fileInfo(_ files: AbsolutePath...) -> AnyPublisher<FileInfo, Error> {
  fileInfo(files)
}

func fileInfo(_ files: [AbsolutePath]) -> AnyPublisher<FileInfo, Error> {
  Empty().eraseToAnyPublisher()
}

func fork(_ arguments: String...) -> AnyPublisher<(), Error> {
  fork(arguments)
}

func fork(_ arguments: [String]) -> AnyPublisher<(), Error> {
  Empty().eraseToAnyPublisher()
}

struct CObjectFile: Query {
  let sourceFile: FileInfo

  func task(for runner: TaskRunner) -> Task<FileInfo, Error> {
    fork("cc", "-c", sourceFile.path.pathString)
      .flatMap { _ in
        fileInfo(
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
    fork(["ld"] + objectFiles.map(\.path.pathString))
      .flatMap { _ in
        fileInfo(
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
    fileInfo(sourceFiles)
      .flatMap(maxPublishers: .unlimited) {
        runner(CObjectFile(sourceFile: $0))
      }
      .collect()
      .flatMap {
        runner(LinkExecutable(objectFiles: $0, executableFile: executableFile))
      }
      .map(\.path)
      .eraseToTask()
  }
}

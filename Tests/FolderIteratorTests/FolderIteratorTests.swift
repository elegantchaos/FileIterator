// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 13/12/2024.
//  All code (c) 2024 - present day, Sam Deane.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ChaosTesting
import FolderIterator
import Testing
import XCTest

let testTree = try! TestTree(
  .dir(
    "project",
    [
      .file("real1.swift"),
      .file("real2.swift"),
      .file(".hidden.swift"),
      .dir(".build", [.file("generated.swift")]),
      .link("link.swift", ".hidden.swift"),
      .rellink("rellink.swift", ".hidden.swift"),
    ]
  )
)

@Test func explicitFileList() async throws {
  let tree = try TestTree(
    .dir(
      "project",
      [
        .file("file1", "contents"),
        .file("file2", "contents"),
      ]
    )
  )

  let result: [URL] = Array(FileIterator(urls: tree.files, followSymlinks: false))
  let names = result.map { $0.lastPathComponent }
  #expect(result.count == 2)
  #expect(names[0] == "file1")
  #expect(names[1] == "file2")
}

@Test func noFollowSymlinks() async throws {
  let result: [URL] = Array(FileIterator(urls: [testTree.url], followSymlinks: false))
  #expect(result.count == 2)
  #expect(result.contains { $0.path.hasSuffix("project/real1.swift") })
  #expect(result.contains { $0.path.hasSuffix("project/real2.swift") })
}

@Test func followSymlinks() async throws {
  let result: [URL] = Array(FileIterator(urls: [testTree.url], followSymlinks: true))
  print(result.map { $0.path }.joined(separator: "\n"))

  #expect(result.count == 3)
  #expect(result.contains { $0.path.hasSuffix("project/real1.swift") })
  #expect(result.contains { $0.path.hasSuffix("project/real2.swift") })
  // Hidden but found through the visible symlink project/link.swift
  #expect(result.contains { $0.path.hasSuffix("project/.hidden.swift") })
}

//   func testFollowSymlinks() throws {
//     #if os(Windows) && compiler(<5.10)
//       try XCTSkipIf(true, "Foundation does not follow symlinks on Windows")
//     #endif
//     let seen = allFilesSeen(iteratingOver: [tmpdir], followSymlinks: true)
//     XCTAssertEqual(seen.count, 3)
//     XCTAssertTrue(seen.contains { $0.path.hasSuffix("project/real1.swift") })
//     XCTAssertTrue(seen.contains { $0.path.hasSuffix("project/real2.swift") })
//     // Hidden but found through the visible symlink project/link.swift
//     XCTAssertTrue(seen.contains { $0.path.hasSuffix("project/.hidden.swift") })
//   }

//   func testTraversesHiddenFilesIfExplicitlySpecified() throws {
//     #if os(Windows) && compiler(<5.10)
//       try XCTSkipIf(true, "Foundation does not follow symlinks on Windows")
//     #endif
//     let seen = allFilesSeen(
//       iteratingOver: [tmpURL("project/.build"), tmpURL("project/.hidden.swift")],
//       followSymlinks: false
//     )
//     XCTAssertEqual(seen.count, 2)
//     XCTAssertTrue(seen.contains { $0.path.hasSuffix("project/.build/generated.swift") })
//     XCTAssertTrue(seen.contains { $0.path.hasSuffix("project/.hidden.swift") })
//   }

//   func testDoesNotFollowSymlinksIfFollowSymlinksIsFalseEvenIfExplicitlySpecified() {
//     // Symlinks are not traversed even if `followSymlinks` is false even if they are explicitly
//     // passed to the iterator. This is meant to avoid situations where a symlink could be hidden by
//     // shell expansion; for example, if the user writes `swift-format --no-follow-symlinks *`, if
//     // the current directory contains a symlink, they would probably *not* expect it to be followed.
//     let seen = allFilesSeen(
//       iteratingOver: [tmpURL("project/link.swift"), tmpURL("project/rellink.swift")],
//       followSymlinks: false
//     )
//     XCTAssertTrue(seen.isEmpty)
//   }

//   func testDoesNotTrimFirstCharacterOfPathIfRunningInRoot() throws {
//     // Find the root of tmpdir. On Unix systems, this is always `/`. On Windows it is the drive.
//     var root = tmpdir!
//     while !root.isRoot {
//       root.deleteLastPathComponent()
//     }
//     var rootPath = root.path
//     #if os(Windows) && compiler(<6.1)
//       if rootPath.hasPrefix("/") {
//         // Canonicalize /C: to C:
//         rootPath = String(rootPath.dropFirst())
//       }
//     #endif
//     // Make sure that we don't drop the beginning of the path if we are running in root.
//     // https://github.com/swiftlang/swift-format/issues/862
//     let seen = allFilesSeen(iteratingOver: [tmpdir], followSymlinks: false, workingDirectory: root)
//       .map(\.relativePath)
//     XCTAssertTrue(
//       seen.allSatisfy { $0.hasPrefix(rootPath) },
//       "\(seen) does not contain root directory '\(rootPath)'")
//   }

//   func testShowsRelativePaths() throws {
//     // Make sure that we still show the relative path if using them.
//     // https://github.com/swiftlang/swift-format/issues/862
//     let seen = allFilesSeen(
//       iteratingOver: [tmpdir], followSymlinks: false, workingDirectory: tmpdir)
//     XCTAssertEqual(Set(seen.map(\.relativePath)), ["project/real1.swift", "project/real2.swift"])
//   }
// }

// extension FileIteratorTests {
//   /// Returns a URL to a file or directory in the test's temporary space.
//   private func tmpURL(_ path: String) -> URL {
//     return tmpdir.appendingPathComponent(path, isDirectory: false)
//   }

//   /// Create an empty file at the given path in the test's temporary space.
//   private func touch(_ path: String) throws {
//     let fileURL = tmpURL(path)
//     try FileManager.default.createDirectory(
//       at: fileURL.deletingLastPathComponent(),
//       withIntermediateDirectories: true
//     )
//     struct FailedToCreateFileError: Error {
//       let url: URL
//     }
//     if !FileManager.default.createFile(atPath: fileURL.path, contents: Data()) {
//       throw FailedToCreateFileError(url: fileURL)
//     }
//   }

//   /// Create a absolute symlink between files or directories in the test's temporary space.
//   private func symlink(_ source: String, to target: String) throws {
//     try FileManager.default.createSymbolicLink(
//       at: tmpURL(source),
//       withDestinationURL: tmpURL(target)
//     )
//   }

//   /// Create a relative symlink between files or directories in the test's temporary space.
//   private func symlink(_ source: String, relativeTo target: String) throws {
//     try FileManager.default.createSymbolicLink(
//       atPath: tmpURL(source).path,
//       withDestinationPath: target
//     )
//   }

//   /// Computes the list of all files seen by using `FileIterator` to iterate over the given URLs.
//   private func allFilesSeen(
//     iteratingOver urls: [URL],
//     followSymlinks: Bool,
//     workingDirectory: URL = URL(fileURLWithPath: ".")
//   ) -> [URL] {
//     let iterator = FileIterator(
//       urls: urls, followSymlinks: followSymlinks)
//     var seen: [URL] = []
//     for next in iterator {
//       seen.append(next)
//     }
//     return seen
//   }
// }

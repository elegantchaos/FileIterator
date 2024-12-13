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

  let result: [URL] = Array(
    FileIterator(urls: tree.files, followSymlinks: false))
  let names = result.map { $0.lastPathComponent }
  #expect(result.count == 2)
  #expect(names[0] == "file1")
  #expect(names[1] == "file2")
}

@Test func noFollowSymlinks() async throws {
  let result: [URL] = Array(
    FileIterator(urls: [testTree.url], followSymlinks: false))
  // print(result.map { $0.path }.joined(separator: "\n"))
  #expect(result.count == 2)
  #expect(result.contains { $0.path.hasSuffix("project/real1.swift") })
  #expect(result.contains { $0.path.hasSuffix("project/real2.swift") })
}

@Test func followSymlinks() async throws {
  let result: [URL] = Array(
    FileIterator(urls: [testTree.url], followSymlinks: true))

  #expect(result.count == 3)
  #expect(result.contains { $0.path.hasSuffix("project/real1.swift") })
  #expect(result.contains { $0.path.hasSuffix("project/real2.swift") })
  // Hidden but found through the visible symlink project/link.swift
  #expect(result.contains { $0.path.hasSuffix("project/.hidden.swift") })
}

@Test func traversesHiddenFilesIfExplicitlySpecified() async throws {
  let urls = [
    testTree.url.appendingPathComponent("project/.build"),
    testTree.url.appendingPathComponent("project/.hidden.swift"),
  ]
  let result: [URL] = Array(
    FileIterator(urls: urls, followSymlinks: false))

  #expect(result.count == 2)
  #expect(result.contains { $0.path.hasSuffix("project/.hidden.swift") })
  #expect(result.contains { $0.path.hasSuffix("project/.build/generated.swift") })
}

@Test func doesNotFollowSymlinksIfFollowSymlinksIsFalseEvenIfExplicitlySpecified() async throws {
  //     // Symlinks are not traversed even if `followSymlinks` is false even if they are explicitly
  //     // passed to the iterator. This is meant to avoid situations where a symlink could be hidden by
  //     // shell expansion; for example, if the user writes `swift-format --no-follow-symlinks *`, if
  //     // the current directory contains a symlink, they would probably *not* expect it to be followed.
  let urls = [
    testTree.url.appendingPathComponent("project/link.swift"),
    testTree.url.appendingPathComponent("project/rellink.swift"),
  ]
  let result: [URL] = Array(
    FileIterator(urls: urls, followSymlinks: false))

  #expect(result.isEmpty)
}

@Test func testDoesNotTrimFirstCharacterOfPathIfRunningInRoot() async throws {
  // Find the root of tmpdir. On Unix systems, this is always `/`. On Windows it is the drive.
  var root = testTree.url
  while !root.isRoot {
    root.deleteLastPathComponent()
  }
  var rootPath = root.path
  #if os(Windows) && compiler(<6.1)
    if rootPath.hasPrefix("/") {
      // Canonicalize /C: to C:
      rootPath = String(rootPath.dropFirst())
    }
  #endif
  // Make sure that we don't drop the beginning of the path if we are running in root.
  //
  let result: [URL] = Array(
    FileIterator(urls: [testTree.url], followSymlinks: false))
  #expect(
    result
      .map(\.relativePath)
      .allSatisfy { $0.hasPrefix(rootPath) }
  )
}

@Test func showsRelativePaths() async throws {
  // Make sure that we still show the relative path if using them.
  //
  let result: [URL] = Array(
    FileIterator(urls: [testTree.url], followSymlinks: false))
  let relative = Set(
    result
      .map { $0.relativeTo(testTree.url) }
      .map(\.relativePath)
  )

  print(result.map { $0.path }.joined(separator: "\n"))
  print(testTree.url)
  print(result.map { $0.relativeTo(testTree.url).relativePath }.joined(separator: "\n"))
  #expect(relative == ["project/real1.swift", "project/real2.swift"])
}

extension URL {
  func relativeTo(_ other: URL) -> URL {
    let s = standardizedFileURL
    let relativePath: String
    if !other.isRoot, s.path.hasPrefix(other.path) {
      relativePath = String(
        s.path.dropFirst(other.path.count).drop(while: { $0 == "/" || $0 == #"\"# }))
    } else {
      relativePath = s.path
    }
    return URL(fileURLWithPath: relativePath, relativeTo: other.standardizedFileURL)
  }
}

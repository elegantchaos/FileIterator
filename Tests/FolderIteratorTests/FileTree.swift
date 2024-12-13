// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 13/12/24.
//  All code (c) 2024 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Description of a file or directory tree to create for testing.

struct TestTree: ~Copyable {
  enum Node {
    case file(String, String)
    case directory(String, [Node])
  }

  /// URL of the root directory we made.
  let url: URL

  init(_ root: Node) throws {
    url = try Self.makeTree(root)
  }

  deinit {
    try? FileManager.default.removeItem(at: url)
  }

  var files: [URL] {
    FileManager.default
      .enumerator(at: url, includingPropertiesForKeys: nil)?
      .compactMap { $0 as? URL }
      .filter { !$0.hasDirectoryPath } ?? []
  }

  /// Make a temporary directory tree for testing.
  /// Returns the URL of the root directory.
  /// The tree will be cleaned up after the test.
  /// If a tree is already set up, it will be cleaned up first.
  static func makeTree(_ tree: Node) throws -> URL {
    let tempDir = FileManager.default.temporaryDirectory
    let tempURL = tempDir.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true)
    try writeTree(tree, to: tempURL)
    return tempURL
  }

  /// Write a file or directory tree to the given root URL.
  static func writeTree(_ tree: Node, to root: URL) throws {
    switch tree {
    case let .file(name, contents):
      print("Writing file \(name) to \(root)")
      try contents.write(to: root.appendingPathComponent(name), atomically: true, encoding: .utf8)
    case let .directory(name, children):
      let directory = root.appendingPathComponent(name)
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      for child in children {
        try writeTree(child, to: directory)
      }
    }
  }
}

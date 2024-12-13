// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 13/12/24.
//  All code (c) 2024 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Description of a file or directory tree to create for testing.

struct TestTree: ~Copyable {
  enum Node {
    case file(String, String)
    case dir(String, [Node])
    case link(String, String)
    case rellink(String, String)

    static func file(_ name: String) -> Node { .file(name, "") }
  }

  /// URL of the root directory we made.
  let url: URL

  /// List of files in the tree, in creation order.
  let files: [URL]

  init(_ root: Node) throws {
    var files: [URL] = []
    self.url = try Self.makeTree(root, files: &files)
    self.files = files
  }

  deinit {
    try? FileManager.default.removeItem(at: url)
    print("Deleted \(url)")
  }

  /// Make a temporary directory tree for testing.
  /// Returns the URL of the root directory.
  /// The tree will be cleaned up after the test.
  /// If a tree is already set up, it will be cleaned up first.
  static func makeTree(_ tree: Node, files: inout [URL]) throws -> URL {
    let tempDir = FileManager.default.temporaryDirectory
    let tempURL = tempDir.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true)
    try writeTree(tree, to: tempURL, files: &files)
    return tempURL
  }

  /// Write a file or directory tree to the given root URL.
  static func writeTree(_ tree: Node, to root: URL, files: inout [URL]) throws {
    switch tree {
    case let .file(name, contents):
      let url = root.appendingPathComponent(name)
      try contents.write(to: url, atomically: true, encoding: .utf8)
      files.append(url)

    case let .link(name, target):
      let url = root.appendingPathComponent(name)
      try FileManager.default.createSymbolicLink(
        at: url,
        withDestinationURL: root.appendingPathComponent(target)
      )
      files.append(url)

    case let .rellink(name, target):
      let url = root.appendingPathComponent(name)
      try FileManager.default.createSymbolicLink(
        atPath: url.path,
        withDestinationPath: target
      )
      files.append(url)

    case let .dir(name, children):
      let directory = root.appendingPathComponent(name)
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      for child in children {
        try writeTree(child, to: directory, files: &files)
      }
    }
  }
}

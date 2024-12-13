// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 13/12/2024.
//  All code (c) 2024 - present day, Sam Deane.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

struct IteratorContext {}

typealias URLIterator = IteratorProtocol<URL>

protocol IteratorChain {
  mutating func next() -> URL?
  var nextIterator: IteratorChain? { get }
}

struct NestedIterator: Sequence, IteratorProtocol {
  private var current: IteratorChain?

  init(first: IteratorChain) {
    self.current = first
  }

  mutating func next() -> URL? {
    repeat {
      if let next = current?.next() {
        return next
      }
      current = current?.nextIterator
    } while current != nil
    return nil
  }
}

/// Iterator for looping over lists of files and directories. Directories are automatically
/// traversed recursively, and we check for files with a ".swift" extension.
public struct FileIterator: Sequence, IteratorProtocol {
  private var it: NestedIterator
  private var visited = Set<URL>()

  /// Create a new file iterator over the given list of file URLs.
  ///
  /// The given URLs may be files or directories. If they are directories, the iterator will recurse
  /// into them.
  public init(urls: [URL], followSymlinks: Bool) {
    self.it = NestedIterator(
      first:
        ContextIterator(
          urls: urls,
          context: IteratorContext(),
          followSymlinks: followSymlinks
        )
    )
  }

  /// Iterate through the "paths" list, and emit the file paths in it. If we encounter a directory,
  /// recurse through it and emit .swift file paths.
  public mutating func next() -> URL? {
    repeat {
      guard let url = it.next() else {
        return nil
      }
      if visited.insert(url.standardizedFileURL).inserted {
        return url
      }
    } while true
  }
}

/// Returns the type of the file at the given URL.
private func fileType(at url: URL) -> FileAttributeType? {
  // We cannot use `URL.resourceValues(forKeys:)` here because it appears to behave incorrectly on
  // Linux.
  return try? FileManager.default.attributesOfItem(atPath: url.path)[.type] as? FileAttributeType
}

struct DirectoryEnumerator: Sequence, IteratorProtocol {
  let iterator: FileManager.DirectoryEnumerator

  init(url: URL) {
    self.iterator = FileManager.default.enumerator(
      at: url,
      includingPropertiesForKeys: nil,
      options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
    )!
  }

  mutating func next() -> URL? {
    let url = iterator.nextObject() as? URL
    print("DirectoryEnumerator.next() -> \(url?.path ?? "nil")")
    return url
  }
}

struct ContextIterator: Sequence, IteratorProtocol, IteratorChain {
  var urlIterator: any URLIterator
  var nextIterator: IteratorChain?
  let context: IteratorContext
  var followSymlinks: Bool

  init(
    urlIterator: any URLIterator, context: IteratorContext, followSymlinks: Bool,
    next: IteratorChain? = nil
  ) {
    self.urlIterator = urlIterator
    self.context = context
    self.nextIterator = next
    self.followSymlinks = followSymlinks
  }

  init(urls: [URL], context: IteratorContext, followSymlinks: Bool) {
    self.init(urlIterator: urls.makeIterator(), context: context, followSymlinks: followSymlinks)
  }

  mutating func next() -> URL? {
    var type: FileAttributeType?
    guard let url = resolved(url: urlIterator.next(), type: &type) else {
      return nil
    }

    switch type {
    case .typeRegular:
      return url

    case .typeDirectory:
      let subIterator = DirectoryEnumerator(url: url)
      nextIterator = ContextIterator(
        urlIterator: subIterator,
        context: context,
        followSymlinks: followSymlinks,
        next: nextIterator
      )

    default:
      break
    }

    return next()
  }

  func resolved(url: URL?, type: inout FileAttributeType?) -> URL? {
    guard let url else {
      return nil
    }

    type = fileType(at: url)
    if type == .typeSymbolicLink,
      let linkPath = try? FileManager.default.destinationOfSymbolicLink(atPath: url.path)
    {
      return resolved(url: URL(fileURLWithPath: linkPath, relativeTo: url), type: &type)
    }

    return url
  }
}

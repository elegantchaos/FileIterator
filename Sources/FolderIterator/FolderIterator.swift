// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 13/12/2024.
//  All code (c) 2024 - present day, Sam Deane.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Context for the iteration.
struct IteratorContext {
  internal init(followSymlinks: Bool, skipHidden: Bool) {
    self.followSymlinks = followSymlinks
    self.skipHidden = skipHidden
  }

  /// Whether to follow symlinks.
  var followSymlinks: Bool

  /// Whether to skip hidden files.
  var skipHidden: Bool
}

typealias URLIterator = IteratorProtocol<URL>

/// Iterator for looping over lists of files and directories. Directories are automatically
/// traversed recursively, and we check for files with a ".swift" extension.
public struct FileIterator: Sequence, IteratorProtocol {
  /// The current iterator.
  /// This is potentially the first in a chain of iterators,
  /// that we process in turn.
  private var current: NestedIterator?

  /// Set of visited URLs, to avoid duplicates.
  private var visited = Set<URL>()

  /// Create a new file iterator over the given list of file URLs.
  ///
  /// The given URLs may be files or directories. If they are directories, the iterator will recurse
  /// into them.
  public init(urls: [URL], followSymlinks: Bool, skipHidden: Bool) {
    let context = IteratorContext(followSymlinks: followSymlinks, skipHidden: skipHidden)
    self.current = NestedIterator(urls: urls, context: context)
  }

  /// Iterate through the "paths" list, and emit the file paths in it. If we encounter a directory,
  /// recurse through it and emit .swift file paths.
  public mutating func next() -> URL? {
    repeat {
      let url = current?.next()
      if let url, visited.insert(url.standardizedFileURL).inserted {
        return url
      }
      if url == nil {
        current = current?.nextIterator
        if current == nil {
          return nil
        }
      }
    } while true
  }
}

struct DirectoryEnumerator: Sequence, IteratorProtocol {
  let iterator: FileManager.DirectoryEnumerator

  init(url: URL, skipHidden: Bool) {
    var options: FileManager.DirectoryEnumerationOptions =
      [.skipsSubdirectoryDescendants]
    if skipHidden {
      options.insert(.skipsHiddenFiles)
      print(options)
    }
    self.iterator = FileManager.default.enumerator(
      at: url,
      includingPropertiesForKeys: nil,
      options: options
    )!
  }

  mutating func next() -> URL? {
    let url = iterator.nextObject() as? URL
    print("DirectoryEnumerator.next() -> \(url?.path ?? "nil")")
    return url
  }
}

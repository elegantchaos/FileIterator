// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 13/12/24.
//  All code (c) 2024 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

struct NestedIterator: Sequence, IteratorProtocol {
  /// Current URL iterator.
  private var urlIterator: any URLIterator

  /// Next iterator in the chain.
  private var linkedIterator: Link

  /// Context for the iterator.
  let context: IteratorContext

  /// Returns the next iterator in the chain.
  /// If there are no more iterators, returns nil.
  var nextIterator: NestedIterator? { linkedIterator.linked }

  init(
    urlIterator: any URLIterator,
    context: IteratorContext,
    next: Link = .none
  ) {
    self.urlIterator = urlIterator
    self.context = context
    self.linkedIterator = next
  }

  init(urls: [URL], context: IteratorContext) {
    self.init(
      urlIterator: urls.makeIterator(),
      context: context
    )
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
      let subIterator = DirectoryEnumerator(url: url, skipHidden: context.skipHidden)
      let next = NestedIterator(
        urlIterator: subIterator,
        context: context,
        next: linkedIterator
      )
      linkedIterator = .next(next)

    default:
      break
    }

    return next()
  }

  private func resolved(url: URL?, type: inout FileAttributeType?) -> URL? {
    guard let url else {
      return nil
    }

    type = fileType(at: url)
    if type == .typeSymbolicLink,
      context.followSymlinks,
      let linkPath = try? FileManager.default.destinationOfSymbolicLink(atPath: url.path)
    {
      return resolved(url: URL(fileURLWithPath: linkPath, relativeTo: url), type: &type)
    }

    return url
  }

  /// A Link to another iterator.
  indirect enum Link {
    case none
    case next(NestedIterator)

    var linked: NestedIterator? {
      switch self {
      case .none: return nil
      case .next(let data): return data
      }
    }

    static func link(to: NestedIterator?) -> Link {
      to == nil ? .none : .next(to!)
    }
  }

}

/// Returns the type of the file at the given URL.
private func fileType(at url: URL) -> FileAttributeType? {
  // We cannot use `URL.resourceValues(forKeys:)` here because it appears to behave incorrectly on
  // Linux.
  return try? FileManager.default.attributesOfItem(atPath: url.path)[.type] as? FileAttributeType
}

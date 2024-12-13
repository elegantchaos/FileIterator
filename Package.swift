// swift-tools-version:6.0

// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 13/12/2024.
//  All code (c) 2024 - present day, Sam Deane.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import PackageDescription

var dependencies: [Package.Dependency] = [
  .package(url: "https://github.com/elegantchaos/ChaosTesting.git", from: "1.0.1")
]

var plugins: [Target.PluginUsage] = []

// Add in support for the ActionBuilder plugin if we're building with it.
if ProcessInfo.processInfo.environment["RESOLVE_ACTION_PLUGINS"] != nil {
  print("'action builder'")
  dependencies.append(contentsOf: [
    .package(url: "https://github.com/elegantchaos/ActionBuilderPlugin.git", from: "2.0.0")
  ])
  plugins.append(.plugin(name: "ActionBuilderPlugin", package: "ActionBuilderPlugin"))
}

let package = Package(
  name: "FolderIterator",

  platforms: [
    .macOS(.v12), .macCatalyst(.v15), .iOS(.v15), .tvOS(.v15), .watchOS(.v8),
  ],

  products: [
    .library(
      name: "FolderIterator",
      targets: ["FolderIterator"]
    )
  ],

  dependencies: dependencies,

  targets: [
    .target(
      name: "FolderIterator",
      dependencies: [],
      plugins: plugins
    ),

    .testTarget(
      name: "FolderIteratorTests",
      dependencies: [
        "FolderIterator",
        "ChaosTesting",
      ]
    ),
  ]
)

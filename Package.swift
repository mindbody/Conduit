// swift-tools-version:5.0
//
//  Package.swift
//  Conduit
//
//  Created by John Hammerlund on 7/12/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import PackageDescription

let package = Package(
    name: "Conduit",
    platforms: [
        .macOS(.v10_11),
        .iOS(.v8),
        .tvOS(.v9),
        .watchOS(.v2),
    ],
    products: [
        .library(name: "Conduit", targets: ["Conduit"]),
        .library(name: "ConduitDynamic", type: .dynamic, targets: ["Conduit"]),
    ],
    dependencies : [],
    targets: [
        .target(name: "Conduit", dependencies: []),
        .testTarget(name: "ConduitTests", dependencies: ["Conduit"]),
    ]
)

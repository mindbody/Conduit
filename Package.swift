// swift-tools-version:4.0
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
    products: [
        .library(
            name: "Conduit",
            targets: ["Conduit"]),
    ],
    dependencies : [],
    targets: [
        .target(
            name: "Conduit",
            dependencies: []),
        .testTarget(
            name: "ConduitTests",
            dependencies: ["Conduit"]),
    ]
)

//
//  URL.swift
//  Conduit
//
//  Created by Eneko Alonso on 7/14/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

extension URL {
    /// Exception-based initializer for URL objects.
    ///
    /// This initializer helps removing boilerplate when creating URL objects,
    /// specially useful for unit and integration testing.
    ///
    /// - Parameter string: Absolute string to convert to URL
    /// - Throws: Throws URLError.badURL if the URL contains invalid characters, or is empty
    init(absoluteString string: String) throws {
        guard let url = URL(string: string) else {
            throw ConduitError.internalFailure(message: "Invalid URL: \(string)")
        }
        self = url
    }
}

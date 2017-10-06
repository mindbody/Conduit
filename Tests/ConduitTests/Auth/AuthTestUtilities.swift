//
//  AuthTestUtilities.swift
//  Conduit
//
//  Created by John Hammerlund on 7/6/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

class AuthTestUtilities {

    static func deserialize(urlEncodedParameterData: Data) -> [String: String]? {
        guard let encodedString = String(data: urlEncodedParameterData, encoding: .utf8) else {
            return nil
        }

        guard var urlComponents = URLComponents(string: "https://google.com") else {
            return nil
        }

        urlComponents.percentEncodedQuery = encodedString

        let params = urlComponents.queryItems?.reduce([String: String]()) { dictionary, queryItem in
            var dict = dictionary
            dict[queryItem.name] = queryItem.value
            return dict
        }

        return params
    }

}

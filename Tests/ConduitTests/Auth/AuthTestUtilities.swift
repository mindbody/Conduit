//
//  AuthTestUtilities.swift
//  Conduit
//
//  Created by John Hammerlund on 7/6/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation
@testable import Conduit

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

    static func makeSecureRandom(length: Int) -> String {
        var buffer = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        return base64URLEncode(Data(bytes: buffer))
    }

    private static func base64URLEncode(_ input: Data) -> String {
        return input.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }

}

class MockSafariAuthorizationStrategy: NSObject, OAuth2AuthorizationStrategy {
    func authorize(request: OAuth2AuthorizationRequest, completion: @escaping (Result<OAuth2AuthorizationResponse>) -> Void) {
        let state = request.state
        let code = AuthTestUtilities.makeSecureRandom(length: 32)
        var params = request.additionalParameters ?? [:]
        params["scope"] = request.scope
        let response = OAuth2AuthorizationResponse(code: code, state: state, customParameters: params)
        completion(.value(response))
    }
}

//
//  UserSessionManager.swift
//  ConduitExample
//
//  Created by John Hammerlund on 6/23/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation
import Conduit

/// This is just a simple example of handling user logins -- app implementations may heavily vary
class UserSessionManager {

    static let shared = UserSessionManager()

    var isUserLoggedIn: Bool {
        return AuthManager.shared.localTokenStore.tokenFor(client: AuthManager.shared.localClientConfiguration, authorization: OAuth2Authorization(type: .bearer, level: .user)) != nil
    }

    func logIn(username: String, password: String, completion: @escaping Result<Void>.Block) {
        let authenticationStrategy = OAuth2PasswordTokenGrantStrategy(username: username, password: password, clientConfiguration: AuthManager.shared.localClientConfiguration)

        authenticationStrategy.issueToken { result in
            switch result {
            case .error(let error):
                completion(.error(error))
            case .value(let token):
                /// Manual token grants must also manually store tokens
                AuthManager.shared.localTokenStore.store(token: token, for: AuthManager.shared.localClientConfiguration, with: OAuth2Authorization(type: .bearer, level: .user))
                completion(.value())
            }
        }
    }

    func logOut() {
        AuthManager.shared.localTokenStore.store(token: nil, for: AuthManager.shared.localClientConfiguration, with: OAuth2Authorization(type: .bearer, level: .user))
    }

}

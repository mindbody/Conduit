//
//  TokenMigratorTests.swift
//  ConduitTests
//
//  Created by Eneko Alonso on 2/20/19.
//  Copyright © 2019 MINDBODY. All rights reserved.
//

import XCTest
import Conduit

class TokenMigratorTests: XCTestCase {

    func testMigrationBetweenDifferentStores() {
        // GIVEN two different token stores
        //   AND a single client configuration
        let configuration = makeConfiguration()
        let source = TokenMigrator.Configuration(tokenStore: makeFileStore(), clientConfiguration: configuration)
        let destination = TokenMigrator.Configuration(tokenStore: makeUserDefaultsStore(), clientConfiguration: configuration)

        // AND source store is populated with tokens
        let tokenAuthorizations = populate(tokenStore: source.tokenStore, for: source.clientConfiguration)

        // WHEN tokens are migrated
        TokenMigrator(source: source, destination: destination).migrateAllTokens()

        // THEN source store should be empty
        //  AND destination store should contain all tokens
        for (token, authorization) in tokenAuthorizations {
            let sourceToken: BearerToken? = source.tokenStore.tokenFor(client: source.clientConfiguration,
                                                                       authorization: authorization)
            let destinationToken: BearerToken? = destination.tokenStore.tokenFor(client: destination.clientConfiguration,
                                                                                 authorization: authorization)
            XCTAssertNil(sourceToken)
            XCTAssertEqual(token, destinationToken)
        }
    }

    func testMigrationBetweenDifferentConfigurations() {
        // GIVEN one token store
        //   AND two different client configurations
        let store = makeFileStore()
        let source = TokenMigrator.Configuration(tokenStore: store, clientConfiguration: makeConfiguration())
        let destination = TokenMigrator.Configuration(tokenStore: store, clientConfiguration: makeConfiguration())

        // AND source store is populated with tokens
        let tokenAuthorizations = populate(tokenStore: source.tokenStore, for: source.clientConfiguration)

        // WHEN tokens are migrated
        TokenMigrator(source: source, destination: destination).migrateAllTokens()

        // THEN source store should be empty
        //  AND destination store should contain all tokens
        for (token, authorization) in tokenAuthorizations {
            let sourceToken: BearerToken? = source.tokenStore.tokenFor(client: source.clientConfiguration,
                                                                       authorization: authorization)
            let destinationToken: BearerToken? = destination.tokenStore.tokenFor(client: destination.clientConfiguration,
                                                                                 authorization: authorization)
            XCTAssertNil(sourceToken)
            XCTAssertEqual(token, destinationToken)
        }
    }

    func testMigrationBetweenDifferentStoresAndConfigurations() {
        // GIVEN two different token stores
        //   AND two different client configurations
        let source = TokenMigrator.Configuration(tokenStore: makeFileStore(), clientConfiguration: makeConfiguration())
        let destination = TokenMigrator.Configuration(tokenStore: makeFileStore(), clientConfiguration: makeConfiguration())

        // AND source store is populated with tokens
        let tokenAuthorizations = populate(tokenStore: source.tokenStore, for: source.clientConfiguration)

        // WHEN tokens are migrated
        TokenMigrator(source: source, destination: destination).migrateAllTokens()

        // THEN source store should be empty
        //  AND destination store should contain all tokens
        for (token, authorization) in tokenAuthorizations {
            let sourceToken: BearerToken? = source.tokenStore.tokenFor(client: source.clientConfiguration,
                                                                       authorization: authorization)
            let destinationToken: BearerToken? = destination.tokenStore.tokenFor(client: destination.clientConfiguration,
                                                                                 authorization: authorization)
            XCTAssertNil(sourceToken)
            XCTAssertEqual(token, destinationToken)
        }
    }

    func testMigrationBetweenSameStoresAndConfigurationsShouldFail() {
        // GIVEN one token store
        //   AND one client configuration
        let store = makeFileStore()
        let configuration = makeConfiguration()
        let source = TokenMigrator.Configuration(tokenStore: store, clientConfiguration: configuration)
        let destination = TokenMigrator.Configuration(tokenStore: store, clientConfiguration: configuration)

        // AND source store is populated with tokens
        let tokenAuthorizations = populate(tokenStore: source.tokenStore, for: source.clientConfiguration)

        // WHEN tokens are migrated
        TokenMigrator(source: source, destination: destination).migrateAllTokens()

        // THEN source store should be empty
        //  AND destination store should be empty
        for (_, authorization) in tokenAuthorizations {
            let sourceToken: BearerToken? = source.tokenStore.tokenFor(client: source.clientConfiguration,
                                                                       authorization: authorization)
            let destinationToken: BearerToken? = destination.tokenStore.tokenFor(client: destination.clientConfiguration,
                                                                                 authorization: authorization)
            XCTAssertNil(sourceToken)
            XCTAssertNil(destinationToken)
        }
    }

    // MARK: - Helpers

    func populate(tokenStore: OAuth2TokenStore,
                  for configuration: OAuth2ClientConfiguration) -> [(token: BearerToken, authorization: OAuth2Authorization)] {
        let tokenAuthorizations = makeTokenAuthorizations()
        for (token, authorization) in tokenAuthorizations {
            XCTAssertTrue(tokenStore.store(token: token, for: configuration, with: authorization))
            let storedToken: BearerToken? = tokenStore.tokenFor(client: configuration, authorization: authorization)
            XCTAssertEqual(token, storedToken)
        }
        return tokenAuthorizations
    }

    func makeTokenAuthorizations() -> [(token: BearerToken, authorization: OAuth2Authorization)] {
        return [
            (token: makeToken(), authorization: OAuth2Authorization(type: .basic, level: .client)),
            (token: makeToken(), authorization: OAuth2Authorization(type: .basic, level: .user)),
            (token: makeToken(), authorization: OAuth2Authorization(type: .bearer, level: .client)),
            (token: makeToken(), authorization: OAuth2Authorization(type: .bearer, level: .user))
        ]
    }

    func makeToken() -> BearerToken {
        return BearerToken(accessToken: UUID().uuidString, expiration: Date.distantFuture)
    }

    func makeConfiguration() -> OAuth2ClientConfiguration {
        let environment = OAuth2ServerEnvironment(tokenGrantURL: URL(fileURLWithPath: "https://example.com"))
        return OAuth2ClientConfiguration(clientIdentifier: UUID().uuidString, clientSecret: UUID().uuidString, environment: environment)
    }

    func makeFileStore() -> OAuth2TokenStore {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(UUID().uuidString)
        return OAuth2TokenFileStore(options: OAuth2TokenFileStoreOptions(storageDirectory: documents))
    }

    func makeUserDefaultsStore() -> OAuth2TokenStore {
        return OAuth2TokenUserDefaultsStore(userDefaults: UserDefaults(), context: UUID().uuidString)
    }
}

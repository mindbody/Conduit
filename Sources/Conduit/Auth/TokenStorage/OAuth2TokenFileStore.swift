//
//  OAuth2TokenFileManagerStore.swift
//  Conduit
//
//  Created by John Hammerlund on 6/12/18.
//  Copyright © 2018 MINDBODY. All rights reserved.
//

import Foundation

/// I/O options for `OAuth2TokenFileStore`
@available(tvOS, unavailable, message: "Persistent file storage is unavailable in tvOS")
public struct OAuth2TokenFileStoreOptions {

    let storageDirectory: URL
    let coordinatesFileAccess: Bool
    let tokenWritingOptions: Data.WritingOptions

    /// Creates a new OAuth2TokenFileStoreOptions
    ///
    /// - Parameters:
    ///   - storageDirectory: The directory in which tokens and token locks should be stored
    ///   - coordinatesFileAccess: If true, then token access is serially handled by concurrent processes.
    ///     Incurs performance overhead due to synchronous I/O. Defaults to `false`
    ///   - tokenWritingOptions: Writing options for token storage. Defaults to `.atomic`
    public init(storageDirectory: URL, coordinatesFileAccess: Bool = false,
                tokenWritingOptions: Data.WritingOptions = .atomic) {
        self.storageDirectory = storageDirectory
        self.coordinatesFileAccess = coordinatesFileAccess
        self.tokenWritingOptions = tokenWritingOptions
    }

}

/// Stores and retrieves OAuth2 tokens from local storage
@available(tvOS, unavailable, message: "Persistent file storage is unavailable in tvOS")
public class OAuth2TokenFileStore: OAuth2TokenStore {

    private let options: OAuth2TokenFileStoreOptions
    private lazy var fileCoordinator: NSFileCoordinator = {
        NSFileCoordinator(filePresenter: nil)
    }()

    /// Creates a new OAuth2TokenFileStore
    ///
    /// - Parameter options: I/O options
    public init(options: OAuth2TokenFileStoreOptions) {
        self.options = options
    }

    private func normalize(filename: String) -> String {
        return filename.replacingOccurrences(of: "/", with: "_").appending(".bin")
    }

    private func tokenFileURLFor(client: OAuth2ClientConfiguration, with authorization: OAuth2Authorization) -> URL {
        let identifier = tokenIdentifierFor(clientConfiguration: client, authorization: authorization)
        let filename = normalize(filename: identifier)
        return options.storageDirectory.appendingPathComponent(filename)
    }

    private func tokenLockFileURLFor(client: OAuth2ClientConfiguration, with authorization: OAuth2Authorization) -> URL {
        let identifier = tokenLockIdentifierFor(clientConfiguration: client, authorization: authorization)
        let filename = normalize(filename: identifier)
        return options.storageDirectory.appendingPathComponent(filename)
    }

    private func prepareForWriting(destination: URL, handler: (URL) -> Bool) -> Bool {
        if options.coordinatesFileAccess == false {
            return handler(destination)
        }
        var error: NSError?
        var success = false
        fileCoordinator.coordinate(writingItemAt: destination, options: [], error: &error) { url in
            success = handler(url)
        }
        return error == nil && success
    }

    private func prepareForDeletion(destination: URL, handler: (URL) -> Bool) -> Bool {
        if options.coordinatesFileAccess == false {
            return handler(destination)
        }
        var error: NSError?
        var success = false
        fileCoordinator.coordinate(writingItemAt: destination, options: .forDeleting, error: &error) { url in
            success = handler(url)
        }
        return error == nil && success
    }

    private func prepareForReading<T>(destination: URL, handler: (URL) -> T?) -> T? {
        if options.coordinatesFileAccess == false {
            return handler(destination)
        }
        var obj: T?
        fileCoordinator.coordinate(readingItemAt: destination, options: [], error: nil) { url in
            obj = handler(url)
        }
        return obj
    }

    public func store<Token>(token: Token?, for client: OAuth2ClientConfiguration,
                             with authorization: OAuth2Authorization) -> Bool where Token: DataConvertible, Token: OAuth2Token {
        let tokenData: Data?
        if let token = token {
            tokenData = try? token.serialized()
        }
        else {
            tokenData = nil
        }
        let storageURL = tokenFileURLFor(client: client, with: authorization)
        if let tokenData = tokenData {
            return prepareForWriting(destination: storageURL) { url in
                do {
                    try tokenData.write(to: url, options: self.options.tokenWritingOptions)
                    return true
                }
                catch {
                    return false
                }
            }
        }
        else {
            return prepareForDeletion(destination: storageURL) { url in
                do {
                    try FileManager.default.removeItem(at: url)
                    return true
                }
                catch {
                    return false
                }
            }
        }
    }

    public func tokenFor<Token>(client: OAuth2ClientConfiguration,
                                authorization: OAuth2Authorization) -> Token? where Token: DataConvertible, Token: OAuth2Token {
        let storageURL = tokenFileURLFor(client: client, with: authorization)
        return prepareForReading(destination: storageURL) { url -> Token? in
            guard let data = FileManager.default.contents(atPath: url.path) else {
                return nil
            }
             return try? Token(serializedData: data)
        }
    }

    public func lockRefreshToken(timeout: TimeInterval, client: OAuth2ClientConfiguration, authorization: OAuth2Authorization) -> Bool {
        let storageURL = tokenLockFileURLFor(client: client, with: authorization)
        let expirationTimestamp = Date().addingTimeInterval(timeout).timeIntervalSince1970
        let timestampString = "\(expirationTimestamp)"
        guard let data = timestampString.data(using: .utf8) else {
            return false
        }
        return prepareForWriting(destination: storageURL) { url in
            do {
                try data.write(to: url, options: .atomic)
                return true
            }
            catch {
                return false
            }
        }
    }

    public func unlockRefreshTokenFor(client: OAuth2ClientConfiguration, authorization: OAuth2Authorization) -> Bool {
        let storageURL = tokenLockFileURLFor(client: client, with: authorization)
        return prepareForDeletion(destination: storageURL) { url in
            do {
                try FileManager.default.removeItem(at: url)
                return true
            }
            catch {
                return false
            }
        }
    }

    public func refreshTokenLockExpirationFor(client: OAuth2ClientConfiguration, authorization: OAuth2Authorization) -> Date? {
        let storageURL = tokenLockFileURLFor(client: client, with: authorization)
        let expirationTimestamp = prepareForReading(destination: storageURL) { url -> TimeInterval? in
            guard let data = FileManager.default.contents(atPath: url.path),
                let timestampString = String(data: data, encoding: .utf8) else {
                return nil
            }
            return TimeInterval(timestampString)
        }

        guard let timestamp = expirationTimestamp else {
            return nil
        }
        return Date(timeIntervalSince1970: timestamp)
    }

}

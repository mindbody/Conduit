## master

#### Breaking
- None

#### Enhancements
- None

#### Bug Fixes
- None

#### Other
- Code coverage is now enforced via codecov.io


## 0.9.2

#### Breaking
- None

#### Enhancements
- Custom refresh grant strategies can be provided on `OAuth2RequestPipelineMiddleware`
- Default token refresh logic has been moved to `OAuth2RefreshTokenGrantStrategy`

#### Bug Fixes
- None

#### Other
- None


## 0.9.1

#### Breaking
- None

#### Enhancements
- None

#### Bug Fixes
- `refresh_token` grants no longer require a scope to be set

#### Other
- None


## 0.9.0

#### Breaking
- Update `XMLNode` interface to better define usage expectations.
  - Default values for `nodes(named:traversal:)` and `node()` methods have been
    removed and traversal algorithm must be now set explicitly.
  - `getValue(name:)` has been updated to always use `.firstLevel` only.
  - New method `findValue(name:traversal:)` has been added, and requires
    the traversal algorithm to be set explicitly.

#### Enhancements
- None

#### Bug Fixes
- None

#### Other
- None


## 0.8.0

#### Breaking
- Update to Xcode 9.3 / Swift 4.1

#### Enhancements
- None

#### Bug Fixes
- None

#### Other
- None


## 0.7.2

#### Breaking
- None

#### Enhancements
- None

#### Bug Fixes
- Fix issue where Logger levels where being ignored.

#### Other
- None


## 0.7.1

#### Breaking
- None

#### Enhancements
- Use Xcode new build system.
- Run CI on Xcode 9.2 image.


## 0.7.0

#### Breaking
- Remove implicit force unwrapped property Conduit.Auth.defaultClientConfiguration (now it is an optional).

#### Enhancements
- Refactor unit tests to allow for parallel testing.

#### Bug Fixes
- None

#### Other
- None


## 0.6.1

#### Breaking
- None

#### Enhancements
- None

#### Bug Fixes
- Fixed a critical issue with public-key pinning in `SSLPinningServerAuthenticationPolicy`

#### Other
- None


## 0.6.0

#### Breaking
- Include node name when throwing a 'node not found' error.

#### Enhancements
- Rakefile tasks now refer to the workspace and include ConduitExampleIOS
- Rakefile task output is more verbose

#### Bug Fixes
- URLSessionClient serial queue naming is now actually unique (only used for debugging)
- Updated ConduitExampleIOS to Swift 4
- Fixed `OAuth2TokenKeychainStore` accessibility
- Fixed legacy token migration within `OAuth2RequestPipelineMiddleware`

#### Other
- Code formatting updates from SwiftLint autocorrect


## 0.5.2

#### Breaking
- None

#### Enhancements
- Synchronous method for issuing authentication tokens

#### Bug Fixes
- None


## 0.5.1

#### Breaking
- None

#### Enhancements
- Unit Test improvements
- Code clean up for additional SwiftLint rules

#### Bug Fixes
- None


## 0.5.0

#### Breaking
- Minimum language version is now Swift 4
- `OAuth2Token` protocol no longer inherits from `NSCoding`, removes `isValid`
- All usage of `BearerOAuth2Token` and `BasicOAuth2Token` have been replaced with `BearerToken` and `BasicToken`
- `OAuth2TokenStore` now requires generic `OAuth2Token & DataConvertible` types
- `RequestSerializer` signature renamed according to Swift style guidelines

#### Enhancements
- All targets now require app-extension-safe API
- Added `BearerToken` struct that leverages Swift-friendly `Codable` and `Decodable` protocols for storage
- Added `BasicToken` struct with limited responsibility and usage
- Added migration extension for `BearerOAuth2Token` => `BearerToken`
- Added backwards-compatibility for `BearerOAuth2Token`
- Deprecated `BearerOAuth2Token` and `BasicOAuth2Token`
- Added test hosts for iOS 11 keychain support

#### Bug Fixes
- None


## 0.4.1

#### Breaking
- None

#### Enhancements
- Improved network logging, including a static request counter

#### Bug Fixes
- None


## 0.4.0

#### Breaking
- `RequestSerializer` no longer handles query parameters
- `XMLNode` value getters have been updated to conform to `XMLTextNodeInitializable`.

#### Enhancements
- `FormEncodedRequestSerializer` now exposes query formatting options for body parameters
- `QueryStringFormattingOptions` now encodes plus symbols by default
- `XMLTextNodeInitializable` protocol has been added.

#### Bug Fixes
- None


## 0.3.0

#### Breaking
- Auth shared `URLSessionClient` defaults to background operation queue.
- Update `URLSessionClient` to return `HTTPURLResponse` for easy retrieval of HTTP status codes.
- Changes on `XMLNode`:
  - Rename `value` property to `text`.
  - Update `XMLNode` subscript method to return `XMLNode?`.
  - Add `.firstLevel` traversal for `XMLNode` to retrieve direct children only.
  - Remove `xmlValue()` in favor of `description`.
  - Conform to `LosslessStringConvertible` protocol.
  - Rename `value()` to `getValue()`.
  - Rename `get(named:)` to `getValue(named:)`.
- Changes on `XML`:
  - Remove `xmlValue()` in favor of `description`.
  - Conform to `LosslessStringConvertible` protocol.
- Remove `XMLNodeIndex`.

#### Enhancements
- Shared `URLSessionClient` with default background operation queue.
- Enhancements to `XMLNode` class:
  - `value` passed to `init` can be any `CustomStringConvertible`.
  - `node(named:)` retrieves the first descendant found with the given name and throws an exception if no matches found.
  - `XMLNode` can be created from Swift dictionaries of `[String: CustomStringConvertible]` (aka. `XMLDictionary`).
  - Add optional counterparts for `getValue()` and `getValue(named:)`

#### Bug Fixes
- None


## 0.2.0

#### Breaking
- Remove unnecessary casting to `NSError` on `SessionTaskCompletion`.
- `XMLNode.children` is no longer optional, defaults to empty array.

#### Enhancements
Enhancements to `XMLNode` class:
- `init` has been improved to allow passing value, attributes and/or children (optional parameters).
- `nodes(named:)` method finds an retrieves a list of descendant nodes matching the given name.
- `getValue()` generic method returns the node text value, if any, converted to any given type that can be constructed from a string by conforming to `LosslessStringConvertible`.
- `get(_:)` generic method returns the value of the first descendant node matching the given name, converted to any given type that can be constructed from a string by conforming to `LosslessStringConvertible`.

#### Bug Fixes
- None


## 0.1.0
- Initial Release

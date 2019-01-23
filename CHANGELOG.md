## master

#### Breaking
- None

#### Enhancements
- None

#### Bug Fixes
- `FormEncodedRequestSerializer` can once again be created publicly

#### Other
- None

## 0.15.1

#### Breaking
- None

#### Enhancements
- Correct XML Serialization for Predefined Escape characters

#### Bug Fixes
- Update XML Serialziation to correctly escape Predefined Escape characters disallowed in XML Requests

#### Other
- None


## 0.15.0

#### Breaking
- None

#### Enhancements
- Add context support to `OAuth2TokenUserDefaultsStore` to enable sandboxing at key level.

#### Bug Fixes
- Update SOAP envelope `encodingStyle` property to non-optional.
- Fix file-based token store when path does not exist.

#### Other
- None


## 0.14.0

#### Breaking
- `serialize(request:bodyParameters:)` is now `public` since `FormEncodedRequestSerializer` is a `final` class.
- `defaultHTTPHeaders` is now `public` since `static` properties cannot be `open`.
- Add `XMLNodeAttributes` to preserve order of attributes on serialized XML nodes

#### Enhancements
- Add new `xmlString(format:)` method to `XML` and `XMLNode`. `XMLSerialization` format options are:
  - `.condensed` -> same single-line condensed output as before.
  - `.prettyPrinted(spaces: Int)` -> human-readable format with flexible indentation level (number of spaces). 

#### Bug Fixes
- None

#### Other
- None


## 0.13.0

#### Breaking

#### Enhancements
- Find XML nodes matching a given function.
- Traverse XML tree upwards with `parent` property.

#### Bug Fixes
- None

#### Other
- None


## 0.12.0

#### Breaking
- Allow direct manipulation of XML trees by converting XML and XMLNode to reference types. 

#### Enhancements
- Add scope to OAuth2AuthorizationResponse
- Improved verbose logging for middleware pipeline.

#### Bug Fixes
- None

#### Other
- None


## 0.11.0

#### Breaking
- `middleware` has been replaced by `requestMiddleware`

#### Enhancements
- `ResponsePipelineMiddleware` added
- `URLSessionClient` now accepts both request and response middleware

#### Bug Fixes
- None

#### Other
- None


## 0.10.3

#### Breaking
- None

#### Enhancements
- None

#### Bug Fixes
- `expires_in` is no longer a required field for access token responses

#### Other
- None


## 0.10.2

#### Breaking
- None

#### Enhancements
- None

#### Bug Fixes
- Added workaround to fix SwiftLint crash: https://github.com/mindbody/Conduit/pull/97

#### Other
- None


## 0.10.1

#### Breaking
- None

#### Enhancements
- None

#### Bug Fixes
- `OAuth2TokenUserDefaultsStore` doesn't default to `.standard` for certain operations

#### Other
- None


## 0.10.0

#### Breaking
- `OAuth2TokenStore` now includes required interface for handling refresh token locks

#### Enhancements
- Loose-IPC is now used to handle a single active session across multiple processes (i.e. app extensions). Token refreshes were previously only safeguarded via serial pipeline; now, they are also protected against concurrent refreshes from other processes using the same storage
- Precise token lock expiration control is available via `OAuth2RequestPipelineMiddleware.tokenRefreshLockRelinquishInterval`
- `OAuth2TokenUserDefaultsStore` adds the ability to store to user-defined `UserDefaults`, most commonly for app group containers
- `OAuth2TokenFileStore` adds additional I/O control, such as multiprocess file coordination via `NSFileCoordinator` and file protection

#### Bug Fixes
- `OAuth2TokenFileStore` solves a design flaw in `OAuth2TokenDiskStore` that prevented multiple tokens to be written for a single OAuth 2.0 client

#### Other
- Code coverage is now enforced via codecov.io
- Added `XMLRequestSerializerTests`
- Added `AuthTokenMigratorTests`
- `OAuth2TokenDiskStore` is now deprecated in favor of `OAuth2TokenFileStore` and `OAuth2TokenUserDefaultsStore`


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

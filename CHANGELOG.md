## Master

#### Breaking
- `XMLNode` value getters have been updated to conform to `XMLTextNodeInitializable`.

#### Enhancements
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

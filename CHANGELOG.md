## Master

#### Breaking
- Remove unnecessary casting to `NSError` on `SessionTaskCompletion`.
- `XMLNode.children` is no longer optional, defaults to empty array.
- Auth shared `URLSessionClient` defaults to background operation queue.
- Rename `XMLNode.value` property to `text`.
- Update `URLSessionClient` to return `HTTPURLResponse` for easy retrieval of HTTP status codes.
- Remove `XMLNodeIndex`.
- Update `XMLNode` subscript method to return `XMLNode?`.
- Add `.firstLevel` traversal for `XMLNode` to retrieve direct children only.
- Remove `xmlValue()` from `XMLNode` and `XML` classes, in favor of `description`.
- Update `XMLNode` and `XML` to conform to `LosslessStringConvertible` protocol.

#### Enhancements
- Shared `URLSessionClient` with default background operation queue.
- Enhancements to `XMLNode` class:
  - `init` has been improved to allow passing value, attributes and/or children (optional parameters).
    - `value` passed can be any `CustomStringConvertible`.
  - `nodes(named:)` method finds an retrieves a list of descendant nodes matching the given name.
  - `node(named:)` retrieves the first descendant found with the given name and throws an exception if no matches found.
  - `getValue()` method retrieves the value converted to a given type that can be constructed from a string by conforming to `LosslessStringConvertible`, or `nil` if the node contains no value.
  - `getValue(named:)` generic method returns the value of the first descendant node matching the given name, converted to any given type that can be constructed from a string by conforming to `LosslessStringConvertible`.
  - `XMLNode` can be created from Swift dictionaries of `[String: CustomStringConvertible]` (aka. `XMLDictionary`).

#### Bug Fixes
- None

## 0.1.0
- Initial Release

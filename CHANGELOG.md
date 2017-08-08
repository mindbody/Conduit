## Master

#### Breaking
- Remove unnecessary casting to `NSError` on `SessionTaskCompletion`.
- `XMLNode.children` is no longer optional, defaults to empty array.
- Auth shared `URLSessionClient` defaults to background operation queue.
- Rename `XMLNode.`value` property to `textNode`.

#### Enhancements
- Shared `URLSessionClient` with default background operation queue.
- Enhancements to `XMLNode` class:
  - `init` has been improved to allow passing value, attributes and/or children (optional parameters).
  - `nodes(named:)` method finds an retrieves a list of descendant nodes matching the given name.
  - `node(named:)` retrieves the first descendant found with the given name and throws an exception if no matches found.
  - `getValue()` generic method returns the node text value, if any, converted to any given type that can be constructed from a string by conforming to `LosslessStringConvertible`.
  - `get(_:)` generic method returns the value of the first descendant node matching the given name, converted to any given type that can be constructed from a string by conforming to `LosslessStringConvertible`.
  - `XMLNode` can be created from Swift dictionaries of `[String: CustomStringConvertible]` (aka. `XMLDictionary`).
  - Add new generic `value()` method to retrieve the value converted to a given type, or `nil` if the node contains no value.

#### Bug Fixes
- None

## 0.1.0
- Initial Release

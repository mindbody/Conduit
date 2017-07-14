//
//  KeychainWrapper.swift
//  KeychainWrapper
//
//  Created by Jason Rendel on 9/23/14.
//  Copyright (c) 2014 Jason Rendel. All rights reserved.
//
//    The MIT License (MIT)
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.

import Foundation

let secMatchLimit: String! = kSecMatchLimit as String
let secReturnData: String! = kSecReturnData as String
let secReturnPersistentRef: String! = kSecReturnPersistentRef as String
let secValueData: String! = kSecValueData as String
let secAttrAccessible: String! = kSecAttrAccessible as String
let secClass: String! = kSecClass as String
let secAttrService: String! = kSecAttrService as String
let secAttrGeneric: String! = kSecAttrGeneric as String
let secAttrAccount: String! = kSecAttrAccount as String
let secAttrAccessGroup: String! = kSecAttrAccessGroup as String

fileprivate let sharedKeychainWrapper = KeychainWrapper()

/// KeychainWrapper is a class to help make Keychain access in Swift more straightforward. It is designed to make 
/// accessing the Keychain services more like using NSUserDefaults, which is much more familiar to people.
internal class KeychainWrapper {

    /// ServiceName is used for the kSecAttrService property to uniquely identify this keychain accessor. 
    /// If no service name is specified, KeychainWrapper will default to using the bundleIdentifier.
    fileprivate var serviceName: String

    /// AccessGroup is used for the kSecAttrAccessGroup property to identify which Keychain Access Group this 
    /// entry belongs to. This allows you to use the KeychainWrapper with shared keychain access between different
    /// applications.
    fileprivate var accessGroup: String?

    private static let defaultServiceName: String = {
        return Bundle.main.bundleIdentifier ?? "SwiftKeychainWrapper"
    }()

    fileprivate convenience init() {
        self.init(serviceName: KeychainWrapper.defaultServiceName)
    }

    /// Create a custom instance of KeychainWrapper with a custom Service Name and optional custom access group.
    ///
    /// - parameter serviceName: The ServiceName for this instance. Used to uniquely identify all keys stored 
    ///                          using this keychain wrapper instance.
    /// - parameter accessGroup: Optional unique AccessGroup for this instance. Use a matching AccessGroup between 
    ///                          applications to allow shared keychain access.
    init(serviceName: String, accessGroup: String? = nil) {
        self.serviceName = serviceName
        self.accessGroup = accessGroup
    }

    /// Default access keychain wrapper access
    class func defaultKeychainWrapper() -> KeychainWrapper {
        return sharedKeychainWrapper
    }

    // MARK: - Methods

    /// Checks if keychain data exists for a specified key.
    ///
    /// - parameter keyName: The key to check for.
    /// - parameter withOptions: Optional KeychainItemOptions to use when retrieving the keychain item.
    /// - returns: True if a value exists for the key. False otherwise.
    func hasValue(forKey keyName: String, withOptions options: KeychainItemOptions? = nil) -> Bool {
        if let _ = self.data(forKey: keyName, withOptions: options) {
            return true
        }
        else {
            return false
        }
    }

   // MARK: Getters

    func integer(forKey keyName: String, withOptions options: KeychainItemOptions? = nil) -> Int? {
        guard let numberValue = self.object(forKey: keyName, withOptions: options) as? NSNumber else {
            return nil
        }

        return numberValue.intValue
    }

    func float(forKey keyName: String, withOptions options: KeychainItemOptions? = nil) -> Float? {
        guard let numberValue = self.object(forKey: keyName, withOptions: options) as? NSNumber else {
            return nil
        }

        return numberValue.floatValue
    }

    func double(forKey keyName: String, withOptions options: KeychainItemOptions? = nil) -> Double? {
        guard let numberValue = self.object(forKey: keyName, withOptions: options) as? NSNumber else {
            return nil
        }

        return numberValue.doubleValue
    }

    func bool(forKey keyName: String, withOptions options: KeychainItemOptions? = nil) -> Bool? {
        guard let numberValue = self.object(forKey: keyName, withOptions: options) as? NSNumber else {
            return nil
        }

        return numberValue.boolValue
    }

    /// Returns a string value for a specified key.
    ///
    /// - parameter keyName: The key to lookup data for.
    /// - parameter withOptions: Optional KeychainItemOptions to use when retrieving the keychain item.
    /// - returns: The String associated with the key if it exists. If no data exists, or the data found 
    ///             cannot be encoded as a string, returns nil.
    func string(forKey keyName: String, withOptions options: KeychainItemOptions? = nil) -> String? {
        guard let keychainData = self.data(forKey: keyName, withOptions: options) else {
            return nil
        }

        return String(data: keychainData, encoding: String.Encoding.utf8) as String?
    }

    /// Returns an object that conforms to NSCoding for a specified key.
    ///
    /// - parameter keyName: The key to lookup data for.
    /// - parameter withOptions: Optional KeychainItemOptions to use when retrieving the keychain item.
    /// - returns: The decoded object associated with the key if it exists. If no data exists, or the data found 
    ///            cannot be decoded, returns nil.
    func object(forKey keyName: String, withOptions options: KeychainItemOptions? = nil) -> NSCoding? {
        guard let keychainData = self.data(forKey: keyName, withOptions: options) else {
            return nil
        }

        return NSKeyedUnarchiver.unarchiveObject(with: keychainData) as? NSCoding
    }

    /// Returns a NSData object for a specified key.
    ///
    /// - parameter keyName: The key to lookup data for.
    /// - parameter withOptions: Optional KeychainItemOptions to use when retrieving the keychain item.
    /// - returns: The NSData object associated with the key if it exists. If no data exists, returns nil.
    func data(forKey keyName: String, withOptions options: KeychainItemOptions? = nil) -> Data? {
        var keychainQueryDictionary = self.setupKeychainQueryDictionary(forKey: keyName, withOptions: options)
        var result: AnyObject?

        // Limit search results to one
        keychainQueryDictionary[secMatchLimit] = kSecMatchLimitOne

        // Specify we want NSData/CFData returned
        keychainQueryDictionary[secReturnData] = kCFBooleanTrue

        // Search
        let status = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(keychainQueryDictionary as CFDictionary, UnsafeMutablePointer($0))
        }

        return status == noErr ? result as? Data : nil
    }

    /// Returns a persistent data reference object for a specified key.
    ///
    /// - parameter keyName: The key to lookup data for.
    /// - parameter withOptions: Optional KeychainItemOptions to use when retrieving the keychain item.
    /// - returns: The persistent data reference object associated with the key if it exists. If no data exists, 
    ///            returns nil.
    func dataRef(forKey keyName: String, withOptions options: KeychainItemOptions? = nil) -> Data? {
        var keychainQueryDictionary = self.setupKeychainQueryDictionary(forKey: keyName, withOptions: options)
        var result: AnyObject?

        // Limit search results to one
        keychainQueryDictionary[secMatchLimit] = kSecMatchLimitOne

        // Specify we want persistent NSData/CFData reference returned
        keychainQueryDictionary[secReturnPersistentRef] = kCFBooleanTrue

        // Search
        let status = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(keychainQueryDictionary as CFDictionary, UnsafeMutablePointer($0))
        }

        return status == noErr ? result as? Data : nil
    }

   // MARK: Setters

    func setInteger(_ value: Int, forKey keyName: String, withOptions options: KeychainItemOptions? = nil) -> Bool {
        return self.setObject(NSNumber(value: value as Int), forKey: keyName, withOptions: options)
    }

    func setFloat(_ value: Float, forKey keyName: String, withOptions options: KeychainItemOptions? = nil) -> Bool {
        return self.setObject(NSNumber(value: value as Float), forKey: keyName, withOptions: options)
    }

    func setDouble(_ value: Double, forKey keyName: String, withOptions options: KeychainItemOptions? = nil) -> Bool {
        return self.setObject(NSNumber(value: value as Double), forKey: keyName, withOptions: options)
    }

    func setBool(_ value: Bool, forKey keyName: String, withOptions options: KeychainItemOptions? = nil) -> Bool {
        return self.setObject(NSNumber(value: value as Bool), forKey: keyName, withOptions: options)
    }

    /// Save a String value to the keychain associated with a specified key. If a String value already exists 
    /// for the given keyname, the string will be overwritten with the new value.
    ///
    /// - parameter value: The String value to save.
    /// - parameter forKey: The key to save the String under.
    /// - parameter withOptions: Optional KeychainItemOptions to use when setting the keychain item.
    /// - returns: True if the save was successful, false otherwise.
    func setString(_ value: String, forKey keyName: String, withOptions options: KeychainItemOptions? = nil) -> Bool {
        if let data = value.data(using: String.Encoding.utf8) {
            return self.setData(data, forKey: keyName, withOptions: options)
        }
        else {
            return false
        }
    }

    /// Save an NSCoding compliant object to the keychain associated with a specified key. If an object already 
    /// exists for the given keyname, the object will be overwritten with the new value.
    ///
    /// - parameter value: The NSCoding compliant object to save.
    /// - parameter forKey: The key to save the object under.
    /// - parameter withOptions: Optional KeychainItemOptions to use when setting the keychain item.
    /// - returns: True if the save was successful, false otherwise.
    func setObject(_ value: NSCoding, forKey keyName: String, withOptions options: KeychainItemOptions? = nil) -> Bool {
        let data = NSKeyedArchiver.archivedData(withRootObject: value)

        return self.setData(data, forKey: keyName, withOptions: options)
    }

    /// Save a NSData object to the keychain associated with a specified key. If data already exists for the given 
    /// keyname, the data will be overwritten with the new value.
    ///
    /// - parameter value: The NSData object to save.
    /// - parameter forKey: The key to save the object under.
    /// - parameter withOptions: Optional KeychainItemOptions to use when setting the keychain item.
    /// - returns: True if the save was successful, false otherwise.
    func setData(_ value: Data, forKey keyName: String, withOptions options: KeychainItemOptions? = nil) -> Bool {
        var keychainQueryDictionary: [String:AnyObject] = self.setupKeychainQueryDictionary(forKey: keyName,
                                                                                            withOptions: options)

        keychainQueryDictionary[secValueData] = value as AnyObject?

        let status: OSStatus = SecItemAdd(keychainQueryDictionary as CFDictionary, nil)

        if status == errSecSuccess {
            return true
        }
        else if status == errSecDuplicateItem {
            return self.updateData(value, forKey: keyName)
        }
        else {
            return false
        }
    }

    /// Remove an object associated with a specified key.
    ///
    /// - parameter keyName: The key value to remove data for.
    /// - parameter withOptions: Optional KeychainItemOptions to use when looking up the keychain item.
    /// - returns: True if successful, false otherwise.
    func removeObject(forKey keyName: String, withOptions options: KeychainItemOptions? = nil) -> Bool {
        let keychainQueryDictionary: [String:AnyObject] = self.setupKeychainQueryDictionary(forKey: keyName)

        // Delete
        let status: OSStatus = SecItemDelete(keychainQueryDictionary as CFDictionary)

        if status == errSecSuccess {
            return true
        }
        else {
            return false
        }
    }

    /// Remove all keychain data added through KeychainWrapper. This will only delete items matching the currnt 
    /// ServiceName and AccessGroup if one is set.
    func removeAllKeys() -> Bool {
        //let keychainQueryDictionary = self.setupKeychainQueryDictionaryForKey(keyName)

        // Setup dictionary to access keychain and specify we are using a generic password (rather than a 
        // certificate, internet password, etc)
        var keychainQueryDictionary: [String:AnyObject] = [secClass: kSecClassGenericPassword]

        // Uniquely identify this keychain accessor
        keychainQueryDictionary[secAttrService] = self.serviceName as AnyObject?

        // Set the keychain access group if defined
        if let accessGroup = self.accessGroup {
            keychainQueryDictionary[secAttrAccessGroup] = accessGroup as AnyObject?
        }

        let status: OSStatus = SecItemDelete(keychainQueryDictionary as CFDictionary)

        if status == errSecSuccess {
            return true
        }
        else {
            return false
        }
    }

    /// Remove all keychain data, including data not added through keychain wrapper.
    ///
    /// - Warning: This may remove custom keychain entries you did not add via SwiftKeychainWrapper.
    ///
    class func wipeKeychain() {
        deleteKeychainSecClass(kSecClassGenericPassword) // Generic password items
        deleteKeychainSecClass(kSecClassInternetPassword) // Internet password items
        deleteKeychainSecClass(kSecClassCertificate) // Certificate items
        deleteKeychainSecClass(kSecClassKey) // Cryptographic key items
        deleteKeychainSecClass(kSecClassIdentity) // Identity items
    }

    // MARK: - Private Methods

    /// Remove all items for a given Keychain Item Class
    ///
    ///
    @discardableResult
    private class func deleteKeychainSecClass(_ obj: AnyObject) -> Bool {
        let query = [secClass: obj]
        let status: OSStatus = SecItemDelete(query as CFDictionary)

        if status == errSecSuccess {
            return true
        }
        else {
            return false
        }
    }

    /// Update existing data associated with a specified key name. The existing data will be overwritten by the new data
    private func updateData(_ value: Data, forKey keyName: String) -> Bool {
        let keychainQueryDictionary: [String:AnyObject] = self.setupKeychainQueryDictionary(forKey: keyName)
        let updateDictionary = [secValueData: value]

        // Update
        let status: OSStatus = SecItemUpdate(keychainQueryDictionary as CFDictionary, updateDictionary as CFDictionary)

        if status == errSecSuccess {
            return true
        }
        else {
            return false
        }
    }

    /// Setup the keychain query dictionary used to access the keychain on iOS for a specified key name. 
    /// Takes into account the Service Name and Access Group if one is set.
    ///
    /// - parameter keyName: The key this query is for
    /// - parameter withOptions: The KeychainItemOptions to use when setting the keychain item.
    /// - returns: A dictionary with all the needed properties setup to access the keychain on iOS
    private func setupKeychainQueryDictionary(forKey keyName: String,
                                              withOptions options: KeychainItemOptions? = nil) -> [String:AnyObject] {
        var keychainQueryDictionary = [String: AnyObject]()

        if let options = options {
            keychainQueryDictionary[secClass] = options.itemClass.keychainAttrValue
            keychainQueryDictionary[secAttrAccessible] = options.itemAccessibility.keychainAttrValue
        }
        else {
            // Setup default access as generic password (rather than a certificate, internet password, etc)
            keychainQueryDictionary[secClass] = KeychainItemClass.genericPassword.keychainAttrValue

            // Protect the keychain entry so it's only valid when the device is unlocked
            keychainQueryDictionary[secAttrAccessible] = KeychainItemAccessibility.whenUnlocked.keychainAttrValue
        }

        // Uniquely identify this keychain accessor
        keychainQueryDictionary[secAttrService] = self.serviceName as AnyObject?

        // Set the keychain access group if defined
        if let accessGroup = self.accessGroup {
            keychainQueryDictionary[secAttrAccessGroup] = accessGroup as AnyObject?
        }

        // Uniquely identify the account who will be accessing the keychain
        let encodedIdentifier: Data? = keyName.data(using: String.Encoding.utf8)

        keychainQueryDictionary[secAttrGeneric] = encodedIdentifier as AnyObject?

        keychainQueryDictionary[secAttrAccount] = encodedIdentifier as AnyObject?

        return keychainQueryDictionary
    }
}

// MARK: - Convenience Class Functions

extension KeychainWrapper {

    /// ServiceName is used for the kSecAttrService property to uniquely identify this keychain accessor. 
    /// If no service name is specified, KeychainWrapper will default to using the bundleIdentifier.
    class var serviceName: String {
        get {
            return sharedKeychainWrapper.serviceName
        }
        @available(*, deprecated: 2.0, message: "Changing serviceName will not be supported in the future. Instead create a new KeychainWrapper instance with a custom service name.")
        set(newServiceName) {
            sharedKeychainWrapper.serviceName = newServiceName
        }
    }

    /// AccessGroup is used for the kSecAttrAccessGroup property to identify which Keychain Access Group this entry 
    /// belongs to. This allows you to use the KeychainWrapper with shared keychain access between different 
    /// applications.
    ///
    /// Access Group defaults to an empty string and is not used until a valid value is set.
    ///
    /// This is a static property and only needs to be set once. To remove the access group property after one has 
    /// been set, set this to an empty string.
    class var accessGroup: String? {
        get {
            return sharedKeychainWrapper.accessGroup
        }
        @available(*, deprecated: 2.0, message: "Changing accessGroup will not be supported in the future. Instead create a new KeychainWrapper instance with a custom accessGroup.")
        set(newAccessGroup) {
            sharedKeychainWrapper.accessGroup = newAccessGroup
        }
    }

    class func hasValueForKey(_ keyName: String) -> Bool {
        return sharedKeychainWrapper.hasValue(forKey: keyName)
    }

    class func stringForKey(_ keyName: String) -> String? {
        return sharedKeychainWrapper.string(forKey: keyName)
    }

    class func objectForKey(_ keyName: String) -> NSCoding? {
        return sharedKeychainWrapper.object(forKey: keyName)
    }

    class func dataForKey(_ keyName: String) -> Data? {
        return sharedKeychainWrapper.data(forKey: keyName)
    }

    class func dataRefForKey(_ keyName: String) -> Data? {
        return sharedKeychainWrapper.dataRef(forKey: keyName)
    }

    class func setString(_ value: String, forKey keyName: String) -> Bool {
        return sharedKeychainWrapper.setString(value, forKey: keyName)
    }

    class func setObject(_ value: NSCoding, forKey keyName: String) -> Bool {
        return sharedKeychainWrapper.setObject(value, forKey: keyName)
    }

    class func setData(_ value: Data, forKey keyName: String) -> Bool {
        return sharedKeychainWrapper.setData(value, forKey: keyName)
    }

    class func removeObjectForKey(_ keyName: String) -> Bool {
        return sharedKeychainWrapper.removeObject(forKey: keyName)
    }

}

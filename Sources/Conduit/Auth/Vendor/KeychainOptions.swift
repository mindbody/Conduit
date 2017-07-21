//
//  KeychainOptions.swift
//  SwiftKeychainWrapper
//
//  Created by James Blair on 4/24/16.
//  Copyright © 2016 Jason Rendel. All rights reserved.
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
#if !os(Linux)

import Foundation

struct KeychainItemOptions {
    let itemClass: KeychainItemClass
    let itemAccessibility: KeychainItemAccessibility

    init(itemClass: KeychainItemClass = .genericPassword,
         itemAccessibility: KeychainItemAccessibility = .whenUnlocked) {
        self.itemClass = itemClass
        self.itemAccessibility = itemAccessibility
    }
}

protocol KeychainAttrRepresentable {
    var keychainAttrValue: CFString { get }
}

// MARK: - KeychainItemClass

/**
 Item class code of a Keychain item.
 */
enum KeychainItemClass {
    /**
     Generic password item.

     The following attribute types (Attribute Item Keys and Values) can be used with an item of this type:
     - kSecAttrAccessible
     - kSecAttrAccessGroup
     - kSecAttrCreationDate
     - kSecAttrModificationDate
     - kSecAttrDescription
     - kSecAttrComment
     - kSecAttrCreator
     - kSecAttrType
     - kSecAttrLabel
     - kSecAttrIsInvisible
     - kSecAttrIsNegative
     - kSecAttrAccount
     - kSecAttrService
     - kSecAttrGeneric
     */
    @available(iOS 2, *)
    case genericPassword

    /**
     Internet password item.

     The following attribute types (Attribute Item Keys and Values) can be used with an item of this type:
     - kSecAttrAccessible
     - kSecAttrAccessGroup
     - kSecAttrCreationDate
     - kSecAttrModificationDate
     - kSecAttrDescription
     - kSecAttrComment
     - kSecAttrCreator
     - kSecAttrType
     - kSecAttrLabel
     - kSecAttrIsInvisible
     - kSecAttrIsNegative
     - kSecAttrAccount
     - kSecAttrSecurityDomain
     - kSecAttrServer
     - kSecAttrProtocol
     - kSecAttrAuthenticationType
     - kSecAttrPort
     - kSecAttrPath
     */
    @available(iOS 2, *)
    case internetPassword

    /**
     Certificate item.

     The following attribute types (Attribute Item Keys and Values) can be used with an item of this type:
     - kSecAttrAccessible
     - kSecAttrAccessGroup
     - kSecAttrCertificateType
     - kSecAttrCertificateEncoding
     - kSecAttrLabel
     - kSecAttrSubject
     - kSecAttrIssuer
     - kSecAttrSerialNumber
     - kSecAttrSubjectKeyID
     - kSecAttrKeyHash
     */
    @available(iOS 2, *)
    case certificate

    /**
     Cryptographic key item.

     The following attribute types (Attribute Item Keys and Values) can be used with an item of this type:
     - kSecAttrAccessible
     - kSecAttrAccessGroup
     - kSecAttrKeyClass
     - kSecAttrLabel
     - kSecAttrApplicationLabel
     - kSecAttrIsPermanent
     - kSecAttrApplicationTag
     - kSecAttrKeyType
     - kSecAttrKeySizeInBits
     - kSecAttrEffectiveKeySize
     - kSecAttrCanEncrypt
     - kSecAttrCanDecrypt
     - kSecAttrCanDerive
     - kSecAttrCanSign
     - kSecAttrCanVerify
     - kSecAttrCanWrap
     - kSecAttrCanUnwrap
     */
    @available(iOS 2, *)
    case key

    /**
     An identity is a certificate together with its associated private key. Because an identity is the combination 
     of a private key and a certificate, this class shares attributes of both kSecClassKey and kSecClassCertificate.
     */
    @available(iOS 2, *)
    case identity
}

private let keychainItemClassLookup: [KeychainItemClass:CFString] = [
    .genericPassword: kSecClassGenericPassword,
    .internetPassword: kSecClassInternetPassword,
    .certificate: kSecClassCertificate,
    .key: kSecClassKey,
    .identity: kSecClassIdentity
]

extension KeychainItemClass : KeychainAttrRepresentable {
    internal var keychainAttrValue: CFString {
        return keychainItemClassLookup[self]!
    }
}

// MARK: - KeychainItemAccessibility
enum KeychainItemAccessibility {
    /**
     The data in the keychain item cannot be accessed after a restart until the device has been unlocked once 
     by the user.

     After the first unlock, the data remains accessible until the next restart. This is recommended for items 
     that need to be accessed by background applications. Items with this attribute migrate to a new device when 
     using encrypted backups.
     */
    @available(iOS 4, *)
    case afterFirstUnlock

    /**
     The data in the keychain item cannot be accessed after a restart until the device has been unlocked once by 
     the user.

     After the first unlock, the data remains accessible until the next restart. This is recommended for items that 
     need to be accessed by background applications. Items with this attribute do not migrate to a new device. Thus, 
     after restoring from a backup of a different device, these items will not be present.
     */
    @available(iOS 4, *)
    case afterFirstUnlockThisDeviceOnly

    /**
     The data in the keychain item can always be accessed regardless of whether the device is locked.

     This is not recommended for application use. Items with this attribute migrate to a new device when using 
     encrypted backups.
     */
    @available(iOS 4, *)
    case always

    /**
     The data in the keychain can only be accessed when the device is unlocked. Only available if a passcode is set
     on the device.

     This is recommended for items that only need to be accessible while the application is in the foreground. Items 
     with this attribute never migrate to a new device. After a backup is restored to a new device, these items are
     missing. No items can be stored in this class on devices without a passcode. Disabling the device passcode 
     causes all items in this class to be deleted.
     */
    @available(iOS 8, *)
    case whenPasscodeSetThisDeviceOnly

    /**
     The data in the keychain item can always be accessed regardless of whether the device is locked.

     This is not recommended for application use. Items with this attribute do not migrate to a new device. Thus, 
     after restoring from a backup of a different device, these items will not be present.
     */
    @available(iOS 4, *)
    case alwaysThisDeviceOnly

    /**
     The data in the keychain item can be accessed only while the device is unlocked by the user.

     This is recommended for items that need to be accessible only while the application is in the foreground. Items
     with this attribute migrate to a new device when using encrypted backups.

     This is the default value for keychain items added without explicitly setting an accessibility constant.
     */
    @available(iOS 4, *)
    case whenUnlocked

    /**
     The data in the keychain item can be accessed only while the device is unlocked by the user.

     This is recommended for items that need to be accessible only while the application is in the foreground. Items 
     with this attribute do not migrate to a new device. Thus, after restoring from a backup of a different device, 
     these items will not be present.
     */
    @available(iOS 4, *)
    case whenUnlockedThisDeviceOnly
}

private let keychainItemAccessibilityLookup: [KeychainItemAccessibility:CFString] = {
    var lookup: [KeychainItemAccessibility:CFString] = [
        .afterFirstUnlock: kSecAttrAccessibleAfterFirstUnlock,
        .afterFirstUnlockThisDeviceOnly: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        .always: kSecAttrAccessibleAlways,
        .alwaysThisDeviceOnly: kSecAttrAccessibleAlwaysThisDeviceOnly,
        .whenUnlocked: kSecAttrAccessibleWhenUnlocked,
        .whenUnlockedThisDeviceOnly: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    ]

    lookup[.whenPasscodeSetThisDeviceOnly] = kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly

    return lookup
}()

extension KeychainItemAccessibility : KeychainAttrRepresentable {
    internal var keychainAttrValue: CFString {
        return keychainItemAccessibilityLookup[self]!
    }
}

#endif

//
//  Cipher.swift
//  Conduit
//
//  Created by John Hammerlund on 12/14/19.
//  Copyright © 2019 MINDBODY. All rights reserved.
//

import Foundation

/// A type that encrypts plaintext data & decrypts corresponding ciphertext data
public typealias Cipher = Encryptor & Decryptor

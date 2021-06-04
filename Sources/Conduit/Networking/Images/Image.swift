//
//  Image.swift
//  
//
//  Created by Eneko Alonso on 6/4/21.
//

#if canImport(AppKit)
import AppKit
typealias Image = NSImage
#elseif canImport(UIKit)
import UIKit
typealias Image = UIImage
#endif

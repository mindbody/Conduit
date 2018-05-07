//
//  HTTPRequestSerializer.swift
//  Conduit
//
//  Created by John Hammerlund on 7/16/16.
//  Copyright © 2016 MINDBODY. All rights reserved.
//

import Foundation
#if os(iOS) || os(tvOS)
    import UIKit
#elseif os(watchOS)
    import WatchKit
#endif

private struct HTTPHeader {
    let name: String
    let value: String
}

/// An _Abstract_ base class for HTTP request serializers.
///
/// Subclassing: Subclasses should override serializedRequestWith(request:bodyParameters:queryParameters)
/// and MUST call super.
open class HTTPRequestSerializer: RequestSerializer {

    // https://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.4
    private static let acceptLanguageHeader: HTTPHeader = {
        func languageComponentFor(languageIdentifier: String, preferenceLevel: Float) -> String {
            return String(format: "\(languageIdentifier);q=%0.1g", preferenceLevel)
        }
        var languageComponents: [String] = []
        var preferenceLevel: Float = 1
        var preferredLanguageIterator = Locale.preferredLanguages.makeIterator()
        while let preferredLanguage = preferredLanguageIterator.next(), preferenceLevel >= 0.5 {
            languageComponents.append(languageComponentFor(languageIdentifier: preferredLanguage,
                                                           preferenceLevel: preferenceLevel))
            preferenceLevel -= 0.1
        }
        return HTTPHeader(name: "Accept-Language", value: languageComponents.joined(separator: ", "))
    }()

    // http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.43
    private static let userAgentHeader: HTTPHeader? = {
        let product: String
        let productVersion: String
        let platform: String?
        var deviceModel: String? = nil
        var operatingSystemVersion: String?
        var deviceScale: String? = nil

        if let executableName = Bundle.main.object(forInfoDictionaryKey: kCFBundleExecutableKey as String) as? String {
            product = executableName
        }
        else {
            product = Bundle.main.object(forInfoDictionaryKey: kCFBundleIdentifierKey as String) as? String ?? "Unknown"
        }

        if let bundleVersionShort = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            productVersion = bundleVersionShort
        }
        else {
            let versionKey = kCFBundleVersionKey as String
            productVersion = Bundle.main.object(forInfoDictionaryKey: versionKey) as? String ?? "Unknown"
        }

        #if os(iOS)
            platform = "iOS"
            deviceModel = UIDevice.current.model
            operatingSystemVersion = UIDevice.current.systemVersion
            deviceScale = String(format: "%0.2f", UIScreen.main.scale)
        #elseif os(watchOS)
            platform = "watchOS"
            deviceModel = WKInterfaceDevice.current().model
            operatingSystemVersion = WKInterfaceDevice.current().systemVersion
            deviceScale = String(format: "%0.2f", WKInterfaceDevice.current().screenScale)
        #elseif os(tvOS)
            platform = "tvOS"
            deviceModel = UIDevice.current.model
            operatingSystemVersion = UIDevice.current.systemVersion
        #elseif os(OSX)
            platform = "Mac OS X"
            operatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersionString
        #endif

        var headerValue: String

        if let platform = platform,
            let operatingSystemVersion = operatingSystemVersion {
            if let deviceModel = deviceModel {
                if let deviceScale = deviceScale {
                    headerValue = "\(product)/\(productVersion) (\(deviceModel); \(platform) " +
                                  "\(operatingSystemVersion); Scale/\(deviceScale))"
                }
                else {
                    headerValue = "\(product)/\(productVersion) (\(deviceModel); \(platform) \(operatingSystemVersion)"
                }
            }
            else {
                headerValue = "\(product)/\(productVersion) (\(platform) \(operatingSystemVersion)"
            }
            return HTTPHeader(name: "User-Agent", value: headerValue)
        }

        return nil
    }()

    /// The subset of HTTP verbs that will never have a request body.
    static let httpMethodsWithNoBody: Set<HTTPRequestBuilder.Method> = [.GET, .HEAD]

    /// Required request headers for HTTP transport according to the W3 spec
    open static let defaultHTTPHeaders: [(String, String)] = {
        return [HTTPRequestSerializer.acceptLanguageHeader, HTTPRequestSerializer.userAgentHeader].compactMap { header in
            guard let header = header else {
                return nil
            }
            return (header.name, header.value)
        }
    }()

    open func serialize(request: URLRequest, bodyParameters: Any? = nil) throws -> URLRequest {

        guard let httpMethod = request.httpMethod, request.url != nil else {
            throw RequestSerializerError.invalidURL
        }

        let httpMethodsWithNoBody = HTTPRequestSerializer.httpMethodsWithNoBody.map { $0.rawValue }

        if bodyParameters != nil && httpMethodsWithNoBody.contains(httpMethod) {
            throw RequestSerializerError.httpVerbDoesNotAllowBodyParameters
        }
        var mutableRequest = request

        let defaultHTTPHeaders = HTTPRequestSerializer.defaultHTTPHeaders
        for header in defaultHTTPHeaders {
            if mutableRequest.value(forHTTPHeaderField: header.0) == nil {
                mutableRequest.setValue(header.1, forHTTPHeaderField: header.0)
            }
        }

        return mutableRequest
    }

}

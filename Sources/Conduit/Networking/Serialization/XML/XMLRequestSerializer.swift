//
//  XMLRequestSerializer.swift
//  Conduit
//
//  Created by John Hammerlund on 12/16/16.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Foundation

/// An HTTPRequestSerializer that serializes request content into XML data
public final class XMLRequestSerializer: HTTPRequestSerializer {

    public override init() {}

    public override func serialize(request: URLRequest, bodyParameters: Any? = nil) throws -> URLRequest {
        var request: URLRequest = try super.serialize(request: request, bodyParameters: bodyParameters)
        if request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.setValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
        }

        if let bodyData: Data = try bodyData(bodyParameters: bodyParameters) {
            request.setValue(String(bodyData.count), forHTTPHeaderField: "Content-Length")
            request.httpBody = bodyData
        }

        return request
    }

    private func bodyData(bodyParameters: Any? = nil) throws -> Data? {
        var bodyData: Data?
        if bodyParameters != nil {
            guard let bodyParameters = bodyParameters as? XML else {
                throw RequestSerializerError.serializationFailure
            }
            var bodyString = String(describing: bodyParameters)
            bodyString = escapePredefinedXMLEntityCharacters(bodyString)
            bodyData = bodyString.data(using: .utf8)
            guard bodyData != nil else {
                throw RequestSerializerError.serializationFailure
            }
        }
        return bodyData
    }

    /**
     These Predefined Entities must be escaped in XML for correct operation.
     
     They are defined in the below documentation -
     https://www.w3.org/TR/xml/#sec-predefined-ent
     
     This defines the requirements in a much more readable manner -
     https://en.wikipedia.org/wiki/List_of_XML_and_HTML_character_entity_references#Predefined_entities_in_XML
     */

    private func escapePredefinedXMLEntityCharacters(_ bodyString: String) -> String {
        var validXMLBodyString = bodyString.replacingOccurrences(of: "&", with: "&amp;")
        validXMLBodyString = validXMLBodyString.replacingOccurrences(of: "'", with: "&apos;")
        return validXMLBodyString
    }

}

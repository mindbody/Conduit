//
//  ProtectedThing.swift
//  ConduitExample
//
//  Created by John Hammerlund on 7/14/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import Conduit

struct ProtectedThing {

    private enum JSONKeys: String {
        case secretThing = "some_secret_thing"
    }

    let secretThing: Int

    init(json: [String : Any]) throws {
        guard let secretThing = json[JSONKeys.secretThing.rawValue] as? Int else {
            throw ResponseDeserializerError.deserializationFailure
        }

        self.secretThing = secretThing
    }

}

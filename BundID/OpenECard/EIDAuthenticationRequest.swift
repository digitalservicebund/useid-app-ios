//
//  EIDAuthenticationRequest.swift
//  BundID
//
//  Created by Fabio Tacke on 25.04.22.
//

import Foundation

struct EIDAuthenticationRequest {
    let issuer: String
    let issuerURL: String
    let subject: String
    let subjectURL: String
    let validity: String
    let terms: AuthenticationTerms
    let readAttributes: FlaggedAttributes
}

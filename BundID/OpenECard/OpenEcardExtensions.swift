//
//  OpenEcardExtensions.swift
//  BundID
//
//  Created by Fabio Tacke on 21.04.22.
//

import Foundation
import OpenEcard

extension ServiceErrorResponseProtocol {
    var errorDescription: String {
        "\(getStatusCode()): \(getErrorMessage() ?? "n/a")"
    }
}

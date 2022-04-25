//
//  IDCardInteractionError.swift
//  BundID
//
//  Created by Fabio Tacke on 22.04.22.
//

import Foundation
import OpenEcard

enum IDCardInteractionError: Error {
    case frameworkError(message: String?)
    case unexpectedReadAttribute(String)
    case cardBlocked
    case cardDeactivated
    case processFailed(resultCode: ActivationResultCode)
}

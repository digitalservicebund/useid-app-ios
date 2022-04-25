//
//  OpenECardHandlerBase.swift
//  BundID
//
//  Created by Fabio Tacke on 25.04.22.
//

import Foundation
import Combine
import OpenEcard

class OpenECardHandlerBase<S>: NSObject where S : Subscriber, IDCardInteractionError == S.Failure, EIDInteractionEvent == S.Input {
    let delegate: OpenECardHandlerDelegate<S>
    
    init(delegate: OpenECardHandlerDelegate<S>) {
        self.delegate = delegate
    }
}

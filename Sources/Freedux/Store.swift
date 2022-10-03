//
//  Store.swift
//  
//
//  Created by Markus Kasperczyk on 01.10.22.
//

#if canImport(SwiftUI)

import Foundation
import SwiftDI
import SwiftUI

@propertyWrapper
public struct Store<I : Interpreter & ObservableObject> : DynamicProperty {
    
    private let env : Dependencies
    @ObservedObject public var wrappedValue : I
    
    public init(env: Dependencies = Dependencies(), wrappedValue: I) {
        self.env = env
        self._wrappedValue = ObservedObject(wrappedValue: wrappedValue)
        inject(environment: env, to: wrappedValue)
    }
    
}

#endif

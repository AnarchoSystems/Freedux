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

enum StoreKey<I : Interpreter & ObservableObject> : Dependency {
    static var defaultValue : I {
        fatalError()
    }
}

@propertyWrapper
public struct Store<I : Interpreter & ObservableObject> : DynamicProperty {
    
    private let env : Dependencies
    @ObservedObject public var wrappedValue : I
    
    public init(env: Dependencies = Dependencies(), wrappedValue: I) {
        var env = env
        self._wrappedValue = ObservedObject(wrappedValue: wrappedValue)
        env[StoreKey<I>.self] = _wrappedValue.wrappedValue
        inject(environment: env, to: wrappedValue)
        self.env = env
    }
    
}

public extension Dependencies {
    
    @MainActor
    func store<I : Interpreter & ObservableObject>() -> I {
        self[StoreKey<I>.self]
    }
    
}

#endif

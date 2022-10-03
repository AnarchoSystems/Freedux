//
//  InterpreterProtocol.swift
//  
//
//  Created by Markus Kasperczyk on 01.10.22.
//

public protocol Interpreter<Symbols, Program> {
    
    associatedtype Symbols
    associatedtype Program
    
    @MainActor
    func parse(_ symbols: Symbols) -> Program
    
    @MainActor
    func runUnsafe(_ program: Program)
    
}


public extension Interpreter {
    
    @MainActor
    func callAsFunction(_ symbols: Symbols) -> Program {
        parse(symbols)
    }
    
}


#if canImport(Combine)

import Combine

public extension Interpreter where Self : ObservableObject, ObjectWillChangePublisher == ObservableObjectPublisher {
    
    @MainActor
    func send(_ symbols: Symbols) {
        objectWillChange.send()
        runUnsafe(parse(symbols))
    }
    
}

#endif

//
//  InterpreterProtocol.swift
//  
//
//  Created by Markus Kasperczyk on 01.10.22.
//

public protocol AnyInterpreter {
    
    @MainActor
    func onBoot()
    
    @MainActor
    func onShutDown()
    
    @MainActor
    func _parse(_ any: Any) -> Any
    
    @MainActor
    func _runUnsafe(_ any: Any)
    
}

public extension AnyInterpreter {
    
    @MainActor
    func _run(_ any: Any) {
        _runUnsafe(_parse(any))
    }
    
}

public protocol Interpreter<Symbols, Program> : AnyInterpreter {
    
    associatedtype Symbols
    associatedtype Program
    
    @MainActor
    func parse(_ symbols: Symbols) -> Program
    
    @MainActor
    func runUnsafe(_ program: Program)
    
}

public extension Interpreter {
    
    @MainActor
    func _parse(_ any: Any) -> Any {
        parse(any as! Symbols)
    }
    
    @MainActor
    func _runUnsafe(_ any: Any) {
        runUnsafe(any as! Program)
    }
    
    @MainActor
    func runUnsafe(_ program: ()) where Program == Void {}
    
    @MainActor
    func onBoot() {}
    
    @MainActor
    func onShutDown() {}

}

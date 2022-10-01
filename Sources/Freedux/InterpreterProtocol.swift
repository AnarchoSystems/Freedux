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
    func setStore(_ store: Any)
    
}

public protocol InterpreterProtocol<State, Symbols, Program> : AnyInterpreter {
    
    associatedtype State
    associatedtype Symbols
    associatedtype Program
    
    var store : MutableStore<State, Symbols, Program>! {get set}
    
    @MainActor
    func parse(_ symbols: Symbols) -> Program
    
}

public extension InterpreterProtocol {
    
    @MainActor
    func _parse(_ any: Any) -> Any {
        parse(any as! Symbols)
    }
    
}

open class _Interpreter<State, Symbols, Program> {
    
    @MainActor
    public var store: MutableStore<State, Symbols, Program>!
    
    @MainActor
    public init() {}
    
    @MainActor
    public func setStore(_ store: Any) {
        guard let store = store as? MutableStore<State, Symbols, Program> else {
            return
        }
        self.store = store
    }

}

public typealias Interpreter<State, Symbols, Program> = _Interpreter<State, Symbols, Program> & InterpreterProtocol

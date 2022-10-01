//
//  InterpreterProtocol.swift
//  
//
//  Created by Markus Kasperczyk on 01.10.22.
//


public protocol InterpreterProtocol<State, Symbols, Program> {
    
    associatedtype State
    associatedtype Symbols
    associatedtype Program
    
    var store : MutableStore<State, Symbols, Program>! {get set}
    
    @MainActor
    func onBoot()
    @MainActor
    func parse(_ symbols: Symbols) -> Program
    @MainActor
    func onShutDown()
    
}

open class _Interpreter<State, Symbols, Program> {
    
    public var store: MutableStore<State, Symbols, Program>!
    
    public init() {}

}

public typealias Interpreter<State, Symbols, Program> = _Interpreter<State, Symbols, Program> & InterpreterProtocol

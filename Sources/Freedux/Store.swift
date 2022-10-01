//
//  Store.swift
//  
//
//  Created by Markus Kasperczyk on 01.10.22.
//

import Foundation

@available(macOS 10.15, *)
public class Store<Interpreter : InterpreterProtocol> : ObservableObject {
    
    @Published public var value : Interpreter.State
    private var interpreter : Interpreter
    private var hasShutDown = false
    
    public init<Env>(_ env: Env,
                     build: (Env) -> (Interpreter.State, Interpreter)) {
        (value, interpreter) = build(env)
        interpreter.store = self
        interpreter.onBoot()
    }
    
    public convenience init(value: Interpreter.State, interpreter: Interpreter) {
        self.init((), build: {(value, interpreter)})
    }
    
    public func send(_ symbols: Interpreter.Symbols) -> Interpreter.Program {
        if hasShutDown {
            print("Warning: receiving actions after shutdown!")
        }
        return interpreter.parse(symbols)
    }
    
    public func shutDown() {
        guard !hasShutDown else {return}
        interpreter.onShutDown()
        hasShutDown = true
    }
    
}

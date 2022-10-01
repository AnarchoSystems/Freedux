//
//  Store.swift
//  
//
//  Created by Markus Kasperczyk on 01.10.22.
//

import Foundation

public class Store<State, Symbols, Program> : ObservableObject {
    
    @MainActor
    public var value : State
    private var interpreter : AnyInterpreter
    private var hasShutdown = false
    
    @MainActor
    fileprivate init<Env, I : InterpreterProtocol>(_ env: Env, _ build: (Env) -> (State, I)) where
    I.State == State, I.Symbols == Symbols, I.Program == Program {
        let (value, interpreter) = build(env)
        self.value = value
        self.interpreter = interpreter
    }
    
    @MainActor
    public static func create<Env, I : InterpreterProtocol>(_ env: Env,
                                                    build: (Env) -> (State, I)) -> Store<State, Symbols, Program> where
    I.State == State, I.Symbols == Symbols, I.Program == Program {
        let result = MutableStore(env, build)
        result.interpreter.setStore(result)
        result.interpreter.onBoot()
        return result
    }
    
    @MainActor
    public static func create<I : InterpreterProtocol>(_ state: State, interpreter: I) -> Store<State, Symbols, Program> where
    I.State == State, I.Symbols == Symbols, I.Program == Program {
        create(()) {(state, interpreter)}
    }
    
    @MainActor
    public func send(_ symbols: Symbols) -> Program {
        if hasShutdown {
            print("receiving actions after shutdown!")
        }
        return interpreter._parse(symbols) as! Program
    }
    
    @MainActor
    public func shutDown() {
        interpreter.onShutDown()
        hasShutdown = true
    }
    
}

public final class MutableStore<State, Symbols, Program> : Store<State, Symbols, Program> {
    
    @MainActor
    @inlinable
    public override var value : State {
        _read{yield super.value}
        _modify{yield &super.value}
    }
    
}

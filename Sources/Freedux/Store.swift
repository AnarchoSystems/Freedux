//
//  Store.swift
//  
//
//  Created by Markus Kasperczyk on 01.10.22.
//

import Foundation
import SwiftDI

public class Store<State, Symbols> : ObservableObject, Reader {
    
    // just to make reflection stop
    public func readValue(from environment: Any) {}
    
    @MainActor
    fileprivate(set) public var value : State {
        willSet {
            objectWillChange.send()
        }
    }
    fileprivate var interpreter : AnyInterpreter
    private var hasShutdown = false
    
    @MainActor
    fileprivate init<I : Interpreter>(_ env: Dependencies,
                                      _ build: (Dependencies) -> (State, I)) where
    I.Symbols == Symbols {
        let (value, interpreter) = build(env)
        self.value = value
        self.interpreter = interpreter
    }
    
    @MainActor
    public static func create<I : Interpreter>(_ env: Dependencies,
                                               build: (Dependencies) -> (State, I)) -> Store<State, Symbols> where
    I.Symbols == Symbols {
        var env = env
        let result = MutableStore<State, I.Symbols, I.Program>(env, build)
        env[StoreKey<State, Symbols, I.Program>.self] = result
        inject(environment: env, to: result.interpreter)
        result.interpreter.onBoot()
        return result
    }
    
    @MainActor
    public static func create<I : Interpreter>(_ state: State, interpreter: I) -> Store<State, Symbols> where
    I.Symbols == Symbols {
        create(.init()) {_ in (state, interpreter)}
    }
    
    @MainActor
    public func send(_ symbols: Symbols) {
        if hasShutdown {
            print("receiving \(symbols) after shutdown!")
            return
        }
        return interpreter._run(symbols)
    }
    
    @MainActor
    public func shutDown() {
        interpreter.onShutDown()
        hasShutdown = true
    }
    
}

public final class MutableStore<State, Symbols, Program> : Store<State, Symbols> {
    
    @MainActor
    @inlinable
    public override var value : State {
        _read{yield super.value}
        _modify{yield &super.value}
    }
    
    @MainActor
    public func parse(_ symbols: Symbols) -> Program {
        interpreter._parse(symbols) as! Program
    }
    
}


public enum StoreKey<State, Symbol, Program> : Dependency {
    public static var defaultValue : MutableStore<State, Symbol, Program> {fatalError()}
}


public extension Injected {
    
    init<State, Symbol, Program>() where Value == MutableStore<State, Symbol, Program>, Whole == Dependencies {
        self = Injected{env in env[StoreKey<State, Symbol, Program>.self]}
    }
    
}

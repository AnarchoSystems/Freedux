//
//  Module.swift
//  
//
//  Created by Markus Kasperczyk on 01.10.22.
//


public protocol Module {
    
    associatedtype Whole
    associatedtype Part = Whole
    associatedtype Symbols
    associatedtype NewSymbols = Symbols
    
    func view(_ whole: Whole) -> Part
    func translate(_ symbols: NewSymbols) -> Symbols
    
}

public extension Module {
    
    @inlinable
    func view(_ whole: Whole) -> Part  where Part == Whole {
        whole
    }
    
    @inlinable
    func translate(_ symbols: NewSymbols) -> Symbols where NewSymbols == Symbols {
        symbols
    }
    
}


public struct AppendingModule<M1 : Module, M2 : Module> : Module where M1.Part == M2.Whole, M1.NewSymbols == M2.Symbols {
    
    public let m1 : M1
    public let m2 : M2
    
    @usableFromInline
    init(m1: M1, m2: M2) {
        self.m1 = m1
        self.m2 = m2
    }
    
    @inlinable
    public func view(_ whole: M1.Whole) -> M2.Part {
        m2.view(m1.view(whole))
    }
    
    @inlinable
    public func translate(_ symbols: M2.NewSymbols) -> M1.Symbols {
        m1.translate(m2.translate(symbols))
    }
    
}


public extension Module {
    
    @inlinable
    func appending<M : Module>(_ module: M) -> AppendingModule<Self, M> {
        .init(m1: self, m2: module)
    }
    
}


import Foundation

public final class ModuleStore<M : Module> : ObservableObject {
    
    @MainActor
    let base : Store<M.Whole, M.Symbols>
    @MainActor
    let module : M
    
    @MainActor
    public var value : M.Part {
        module.view(base.value)
    }
    
    @MainActor
    init(base: Store<M.Whole, M.Symbols>, module: M) {
        self.base = base
        self.module = module
    }
    
    @MainActor
    public func send(_ symbols: M.NewSymbols) {
        base.send(module.translate(symbols))
    }
    
    public var objectWillChange : ObjectWillChangePublisher {
        base.objectWillChange
    }
    
}

public extension Store {
    
    @MainActor
    func map<M : Module>(_ module: M) -> ModuleStore<M> where M.Symbols == Symbols, M.Whole == State {
        .init(base: self, module: module)
    }
    
}

public extension ModuleStore {
    
    @MainActor
    func map<M2 : Module>(_ module: M2) -> ModuleStore<AppendingModule<M, M2>> {
        .init(base: base, module: self.module.appending(module))
    }
    
}

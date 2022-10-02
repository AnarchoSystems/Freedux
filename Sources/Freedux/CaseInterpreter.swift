//
//  CaseInterpreter.swift
//  
//
//  Created by Markus Kasperczyk on 02.10.22.
//

import CasePaths

public protocol CaseInterpreter : Interpreter {
    
    associatedtype Command = Symbols
    
    @MainActor
    var casePath : CasePath<Symbols, Command> {get}
    
    @MainActor
    func parse(_ command: Command) -> Program
    
    @MainActor
    func emptyProgram() -> Program
    
}

public extension CaseInterpreter where Command == Symbols {
    
    var casePath : CasePath<Symbols, Command> {
        CasePath(embed: {$0}, extract: {$0})
    }
    
}

public extension CaseInterpreter {
    
    @MainActor
    func parse(_ symbols: Symbols) -> Program {
        guard let command = casePath.extract(from: symbols) else {
            return emptyProgram()
        }
        return parse(command)
    }
 
    func emptyProgram() where Program == Void {}
    
    func emptyProgram<T>() -> T? where Program == T? {nil}
    
}

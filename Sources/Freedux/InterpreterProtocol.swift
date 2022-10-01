//
//  InterpreterProtocol.swift
//  
//
//  Created by Markus Kasperczyk on 01.10.22.
//


@available(macOS 10.15, *)
public protocol InterpreterProtocol {
    
    associatedtype Symbols
    associatedtype Program
    associatedtype State
    
    var store : Store<Self>! {get set}
    
    func onBoot()
    func parse(_ symbols: Symbols) -> Program
    func onShutDown()
    
}

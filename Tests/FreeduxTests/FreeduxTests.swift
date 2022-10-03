import XCTest
import Freedux
import SwiftDI
import CasePaths

#if canImport(SwiftUI)
import SwiftUI
#endif

final class FreeduxTests: XCTestCase {
    
    #if canImport(SwiftUI)
    
    @MainActor
    func testInterpret() {
        
        do {
            let ref = Store(wrappedValue: TestInterpreter())
            ref.wrappedValue.send(doSomething())
        }
        
    }
    
    #endif
    
}

enum TestCommand<T> {
    case onBoot
    case pure(T)
    case fetchInt(String,
                  (Int) -> TestCommand<T>)
    case mutate( (inout Int) -> T,
                 (T) -> TestCommand<T>)
    case assert42
    case onShutdown
}

extension TestCommand where T == Void {
    
    static var nop : Self {.pure(())}
    
    static func mutate(_ change: @escaping (inout Int) -> Void) -> Self {
        .mutate(change, {.nop})
    }
    
}

func doSomething() -> TestCommand<Void> {
    .fetchInt("meaning of life") {meaning in
            .mutate({$0 = meaning}) {
                .assert42
            }
    }
}

struct LazyIdentity<T> {
    
    let runUnsafe :
    () -> T
    
    static func pure(_ t: T) -> Self {
        .init{t}
    }
    
    func then<U>(_ trafo: @escaping
                 (T) -> LazyIdentity<U>) -> LazyIdentity<U> {
        .init{trafo(runUnsafe()).runUnsafe()}
    }
    
}

final class TestInterpreter : Interpreter, ObservableObject {
    
    private var didBoot = false
    private var value : Int = 0
    
    @Constant(\.fetchInterpreter) var fetch
    
    init() {
        runUnsafe(parse(.onBoot))
    }
    
    nonisolated func parse(_ symbols: TestCommand<Void>) -> LazyIdentity<Void> {
        switch symbols {
        case .onBoot:
            return LazyIdentity {self.didBoot = true}
        case .pure(let t):
            return .pure(t)
        case .fetchInt(let string, let then):
            return fetch.parse((string, then))
        case .mutate(let change, let then):
            return LazyIdentity {change(&self.value)}
                .then {
                    return self.parse(then($0))
                }
        case .assert42:
            return LazyIdentity{ XCTAssert(self.value == 42) }
        case .onShutdown:
            return LazyIdentity {XCTAssert(self.didBoot)}
        }
    }
    
    deinit {
        runUnsafe(parse(.onShutdown))
    }
    
    nonisolated func runUnsafe(_ program: LazyIdentity<()>) {
        program.runUnsafe()
    }
    
}

struct FetchInterpreter : CaseInterpreter, Dependency {
    
    typealias Symbols = TestCommand<Void>
    typealias Program = LazyIdentity<Void>
    
    static let defaultValue = FetchInterpreter()
    
    let casePath : CasePath<TestCommand<Void>, (String, (Int) -> TestCommand<Void>)> = /TestCommand<Void>.fetchInt
    
    nonisolated func parse(_ command: (String, (Int) -> TestCommand<Void>)) -> LazyIdentity<Void> {
        let (string, then) = command
        return LazyIdentity {
            // do some API call...
            if string == "meaning of life" {
                return 42
            }
            else {
                return -1
            }
        }.then {int in
            guard case .fetchInt(let str, let then) = then(int) else {return .init{}}
            return parse((str, then))
        }
    }
    
    func emptyProgram() -> LazyIdentity<Void> {
        .pure(())
    }
    
    nonisolated func runUnsafe(_ program: LazyIdentity<Void>) {
        program.runUnsafe()
    }
    
}


extension Dependencies {
    
    @MainActor
    var fetchInterpreter : FetchInterpreter {
        self[FetchInterpreter.self]
    }
    
}

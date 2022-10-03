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
    case fetchInt(String,
                  (Int) -> TestCommand<T>)
    case mutate( (inout Int) -> T,
                 (T) -> TestCommand<T>)
    case assert42
    case onShutdown
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
    private var didFetch = false
    private var didMutate = false
    private var didAssert42 = false
    private var didShutdown = false
    private var value : Int = 0
    
    @Constant(\.fetchInterpreter) var fetch
    
    init() {
        runUnsafe(parse(.onBoot))
    }
    
    nonisolated func parse(_ symbols: TestCommand<Void>) -> LazyIdentity<Void> {
        switch symbols {
        case .onBoot:
            return LazyIdentity {self.didBoot = true}
        case .fetchInt(let string, let then):
            return fetch.parse((string, then)).then {self.didFetch = true; return .pure(())}
        case .mutate(let change, let then):
            return LazyIdentity {change(&self.value); self.didMutate = true}
                .then {
                    return self.parse(then($0))
                }
        case .assert42:
            return LazyIdentity{ XCTAssert(self.value == 42); self.didAssert42 = true }
        case .onShutdown:
            return LazyIdentity {self.didShutdown = true}
        }
    }
    
    deinit {
        runUnsafe(parse(.onShutdown))
        XCTAssert(didBoot)
        XCTAssert(didFetch)
        XCTAssert(didMutate)
        XCTAssert(didAssert42)
        XCTAssert(didShutdown)
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
    
    @Injected({$0.store()}) var store : TestInterpreter
    
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
            store.parse(then(int))
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

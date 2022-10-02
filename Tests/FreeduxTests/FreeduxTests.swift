import XCTest
import Freedux
import SwiftDI
import CasePaths

final class FreeduxTests: XCTestCase {
    
    @MainActor
    func testInterpret() {
        
        let ref = Store.create(0, interpreter: TestInterpreter())
        ref.send(doSomething())
        ref.shutDown()
        
    }
    
}

enum TestCommand<T> {
    case onBoot
    case pure(T)
    case fetchInt(String,
                  @MainActor (Int) -> TestCommand<T>)
    case mutate(@MainActor (inout Int) -> T,
                @MainActor(T) -> TestCommand<T>)
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
    @MainActor () -> T
    
    static func pure(_ t: T) -> Self {
        .init{t}
    }
    
    func then<U>(_ trafo: @escaping
                 @MainActor (T) -> LazyIdentity<U>) -> LazyIdentity<U> {
        .init{trafo(runUnsafe()).runUnsafe()}
    }
    
}

final class TestInterpreter : Interpreter {
    
    private var didBoot = false
    
    func onBoot() {
        store.send(.onBoot)
    }
    
    @Injected(Dependencies.store) var store : MutableStore<Int, TestCommand<Void>, LazyIdentity<Void>>
    
    @Constant(\.fetchInterpreter) var fetch
    
    func parse(_ symbols: TestCommand<Void>) -> LazyIdentity<Void> {
        switch symbols {
        case .onBoot:
            return LazyIdentity {self.didBoot = true}
        case .pure(let t):
            return .pure(t)
        case .fetchInt(let string, let then):
            return fetch.parse((string, then))
        case .mutate(let change, let then):
            return LazyIdentity {change(&self.store.value)}
                .then {
                    return self.store.parse(then($0))
                }
        case .assert42:
            return LazyIdentity{ XCTAssert(self.store.value == 42) }
        case .onShutdown:
            return LazyIdentity {XCTAssert(self.didBoot)}
        }
    }
    
    func onShutDown()  {
        store.send(.onShutdown)
    }
    
    func runUnsafe(_ program: LazyIdentity<()>) {
        program.runUnsafe()
    }
    
}

struct FetchInterpreter : CaseInterpreter, Dependency {
    
    typealias Symbols = TestCommand<Void>
    typealias Program = LazyIdentity<Void>
    
    static let defaultValue = FetchInterpreter()
    
    @Injected(Dependencies.store) var store : MutableStore<Int, TestCommand<Void>, LazyIdentity<Void>>
    
    let casePath : CasePath<TestCommand<Void>, (String,  @MainActor (Int) -> TestCommand<Void>)> = /TestCommand<Void>.fetchInt
    
    func parse(_ command: (String, @MainActor (Int) -> TestCommand<Void>)) -> LazyIdentity<Void> {
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
            self.store.parse(then(int))
        }
    }
    
    func emptyProgram() -> LazyIdentity<Void> {
        .pure(())
    }
    
    func runUnsafe(_ program: LazyIdentity<Void>) {
        program.runUnsafe()
    }
   
}


extension Dependencies {
    
    @MainActor
    var fetchInterpreter : FetchInterpreter {
        self[FetchInterpreter.self]
    }
    
}

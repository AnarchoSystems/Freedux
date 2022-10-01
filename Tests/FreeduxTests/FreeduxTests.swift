import XCTest
import Freedux

final class FreeduxTests: XCTestCase {
    
    @MainActor
    func testInterpret() {
        
        let ref = Store.create(0, interpreter: TestInterpreter())
        let monad = ref.send(doSomething())
        monad.runUnsafe()
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

final class TestInterpreter : Interpreter<Int, TestCommand<Void>, LazyIdentity<Void>> {
    
    private var didBoot = false
    
    func onBoot() {
        store.send(.onBoot).runUnsafe()
    }
    
    func parse(_ symbols: TestCommand<Void>) -> LazyIdentity<Void> {
        switch symbols {
        case .onBoot:
            return LazyIdentity {self.didBoot = true}
        case .pure(let t):
            return .pure(t)
        case .fetchInt(let string, let then):
            return LazyIdentity {
                // do some API call...
                if string == "meaning of life" {
                    return 42
                }
                else {
                    return -1
                }
            }.then {int in
                self.store.send(then(int))
            }
        case .mutate(let change, let then):
            return LazyIdentity {change(&self.store.value)}
                .then {
                    return self.store.send(then($0))
                }
        case .assert42:
            return LazyIdentity{ XCTAssert(self.store.value == 42) }
        case .onShutdown:
            return LazyIdentity {XCTAssert(self.didBoot)}
        }
    }
    
    func onShutDown()  {
        store.send(.onShutdown).runUnsafe()
    }
    
}

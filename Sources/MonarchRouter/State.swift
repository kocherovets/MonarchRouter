//
//  Store.swift
//  MonarchRouter
//
//  Created by Eliah Snakin on 21/11/2018.
//  nikans.com
//

import Foundation

public enum DispatchRouteOption {
    /// Keeps presented VCs if only need to switch the junction option
    /// i.e.: when switching to a tab by it's root Route, when the tab already contains presented stack
    case junctionsOnly
}

public struct RoutersStack {
    public init(_ routersStack: [RoutingNodeType]) {
        self.routersStack = routersStack
    }

    public let routersStack: [RoutingNodeType]

    func isContains(node: RoutingNodeType) -> Bool {
        isContains(stack: [node])
    }

    func isContains(stack: [RoutingNodeType]) -> Bool {
        guard stack.count > 0 else { return true }

        var index: Int?
        for i in 0 ..< routersStack.count {
            if routersStack[i].uuid == stack[0].uuid {
                index = i
                break
            }
        }
        if let index = index {
            for i in 0 ..< stack.count {
                if stack[i].uuid != routersStack[i + index].uuid {
                    return false
                }
            }
        } else {
            return false
        }
        return true
    }

    func append(_ node: RoutingNodeType) -> RoutersStack {
        RoutersStack(routersStack + [node])
    }
}

/// State Store for the Router.
/// Initialize one to change routes via `dispatch(_ request:)`.
public final class RouterStore {
    /// Primary method to make a Routing Request.
    /// - parameter request: Routing Request.
    /// - parameter options: Special options for navigation (see `DispatchRouteOption` enum).
    public func dispatch(_ request: RoutingRequestType, options: [DispatchRouteOption] = []) {
        state = routerReducer(request: request, router: router(), state: state, options: options)
    }

    /// Primary initializer for a new `RouterStore`.
    /// - parameter router: Describes the Coordinator hierarchy for the current application. Autoclosure.
    public init(router: @autoclosure @escaping () -> RoutingNodeType) {
        self.router = router
        state = RouterState()
        reducer = routerReducer(request:router:state:options:)
    }

    /// Initializer allowing for overriding the State and Reducer.
    /// - parameter router: Describes the Coordinator hierarchy for the current application. Autoclosure.
    /// - parameter state: State holds the current `RoutingNodes` stack.
    /// - parameter reducer: Function to calculate a new State.
    public init(
        router: @autoclosure @escaping () -> RoutingNodeType,
        state: RouterStateType,
        reducer: @escaping (_ request: RoutingRequestType, _ router: RoutingNodeType, _ state: RouterStateType, _ options: [DispatchRouteOption]) -> RouterStateType)
    {
        self.router = router
        self.state = state
        self.reducer = reducer
    }

    /// Describes the Coordinator hierarchy for the current application.
    let router: () -> RoutingNodeType

    /// State holds the current `RoutingNodes` stack.
    var state: RouterStateType

    /// Function to calculate a new State.
    /// Implements navigation via `RoutingNodeType`'s `setRequest` callback.
    /// Unwinds unused `RoutingNodes` (see `RoutingNodeType`'s `unwind()` function).
    let reducer: (_ request: RoutingRequestType, _ router: RoutingNodeType, _ state: RouterStateType, _ options: [DispatchRouteOption]) -> RouterStateType
}

/// Describes `RouterState` object.
/// State holds the stack of Routers.
public protocol RouterStateType {
    /// The stack of Routers.
    var routersStack: [RoutingNodeType] { get set }
}

/// State holds the current Routers stack.
struct RouterState: RouterStateType {
    /// The resulting Routers after performing the Request.
    var routersStack = [RoutingNodeType]()
}

/// Function to calculate a new State.
/// Implements navigation via `RoutingNodeType`'s `performRequest` callback.
/// Unwinds unused `RoutingNode`s (see `RoutingNodeType`'s `unwind()` function).
/// - parameter request: Request to perform.
/// - parameter router: Describes the Coordinator hierarchy for the current application.
/// - parameter state: State holds the current `RoutingNodes` stack.
func routerReducer(request: RoutingRequestType, router: RoutingNodeType, state: RouterStateType, options: [DispatchRouteOption]) -> RouterStateType
{
    func unwind(stack: [RoutingNodeType], comparing newStack: [RoutingNodeType]) {
        // Recursively called for each substack
        stack.enumerated().forEach { i, element in
            if let substack = element.substack {
                unwind(stack: substack, comparing: newStack[safe: i]?.substack ?? [])
            }
        }

        // Dismissing substacks that are not present anymore
        stack.enumerated()
            .filter({ i, node in
                node.substack != nil && newStack[safe: i]?.substack == nil
            })
            .reversed()
            .forEach { _, node in
                node.dismissSubstack()
            }

        // Finding the first RoutingNode in the stack that is not the same as in the previous Routers stack
        if let firstDifferenceIndex = stack.enumerated().first(where: { i, node in
            guard newStack.count > i else { return true }
            return node.getPresentable() != newStack[i].getPresentable()
        })?.offset {
            // Unwinding unused `RoutingNode`s in reversed order
            stack[firstDifferenceIndex ..< stack.count]
                .reversed()
                .forEach { node in
                    node.dismissSubstack()
                    node.unwind()
                }
        }
    }

    var routersStack = state.routersStack
    print("-0------------------------------")
    print("before removed")
    log(routersStack: routersStack)

    removeUnusedRoutes(routersStack: &routersStack)
    print("000")
    print("removed")
    log(routersStack: routersStack)

    var newRoutersStack = [RoutingNodeType]()
    var condition: ((RoutingNodeType) -> Bool) = { _ in true }
    var badUUIDs = [String: Bool]()

    func findNewRoutersStack(routersStack: [RoutingNodeType], badUUIDs: inout [String: Bool]) -> [RoutingNodeType]? {
        var newRoutersStack = [RoutingNodeType]()
        if let node = lastNode(routersStack: routersStack) {
            let stack = node.testRequest(request, [], { node.uuid != $0.uuid }, &badUUIDs)
            badUUIDs[node.uuid] = nil
            if stack.count > 1 {
                print("222")
                newRoutersStack = routersStack
                addStackAfterLastNode(routersStack: &newRoutersStack, suffixStack: Array(stack.suffix(from: 1)))
//                condition = { stack.last?.uuid == $0.uuid }
            } else if let node = stack.first, let substack = node.substack, substack.count > 0 {
                print("333")
                newRoutersStack = routersStack
                addSubstackForLastNode(routersStack: &newRoutersStack, suffixStack: substack)
//                condition = { substack.last?.uuid == $0.uuid }
            }
        }
        if newRoutersStack.count == 0 {
            return nil
        }
        return newRoutersStack
    }

    var routersStack2 = routersStack
    while routersStack2.count > 0 {
        if let stack = findNewRoutersStack(routersStack: routersStack2, badUUIDs: &badUUIDs) {
            newRoutersStack = stack
            break
        }
        routersStack2 = removeLastNode(routersStack: routersStack2)
        print("444")
        log(routersStack: routersStack2)
    }

    if newRoutersStack.count == 0 {
        print("111")
        newRoutersStack = router.testRequest(request, [], { _ in true }, &badUUIDs)
    }

    print("newRoutersStack")
    log(routersStack: newRoutersStack)

    unwind(stack: routersStack, comparing: newRoutersStack)

    let uuid = lastNode(routersStack: newRoutersStack)?.uuid
    condition = { uuid == $0.uuid }
    router.performRequest(request, [], options, condition)

    return RouterState(routersStack: newRoutersStack)
}

func removeUnusedRoutes(routersStack: inout [RoutingNodeType]) {
    if let index = routersStack.lastIndex(where: { $0.getPresentable().view.window != nil }) {
        routersStack = Array(routersStack.prefix(index + 1))
    } else {
        routersStack = []
    }
    for i in 0 ..< routersStack.count {
        if routersStack[i].substack != nil {
            removeUnusedRoutes(routersStack: &(routersStack[i].substack!))
        }
    }
}

func lastNode(routersStack: [RoutingNodeType]) -> RoutingNodeType? {
    for node in routersStack {
        if let substack = node.substack, substack.count > 0 {
            return lastNode(routersStack: substack)
        }
    }
    return routersStack.last
}

func removeLastNode(routersStack: [RoutingNodeType]) -> [RoutingNodeType] {
    if routersStack.count == 0 {
        return []
    }
    var routersStack = routersStack
    if let substack = routersStack.last?.substack, substack.count > 0 {
        routersStack[routersStack.count - 1].substack = removeLastNode(routersStack: substack)
        return routersStack
    }
    return Array(routersStack.prefix(routersStack.count - 1))
}

func addStackAfterLastNode(routersStack: inout [RoutingNodeType], suffixStack: [RoutingNodeType]) {
    for i in 0 ..< routersStack.count {
        if let substack = routersStack[i].substack, substack.count > 0 {
            addStackAfterLastNode(routersStack: &(routersStack[i].substack!), suffixStack: suffixStack)
            return
        }
    }
    routersStack = routersStack + suffixStack
}

func addSubstackForLastNode(routersStack: inout [RoutingNodeType], suffixStack: [RoutingNodeType]) {
    for i in 0 ..< routersStack.count {
        if let substack = routersStack[i].substack, substack.count > 0 {
            addSubstackForLastNode(routersStack: &(routersStack[i].substack!), suffixStack: suffixStack)
            return
        }
    }
    routersStack[routersStack.count - 1].substack = suffixStack
}

func log(routersStack: [RoutingNodeType], level: Int = 1) {
    routersStack.forEach {
        print(level, $0.uuid)
        print(level, $0.getPresentable().description.replacingOccurrences(of: "MonarchRouterExample.", with: ""))
        if let substack = $0.substack, substack.count > 0 {
            log(routersStack: substack, level: level + 1)
        }
    }
}


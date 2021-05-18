//
//  Store.swift
//  MonarchRouter
//
//  Created by Eliah Snakin on 21/11/2018.
//  nikans.com
//

import UIKit

public struct TreeNode: CustomStringConvertible {
    public init(route: RoutingNodeType, kind: TreeNode.Kind) {
        self.route = route
        self.kind = kind
    }

    public enum Kind {
        case modal
        case child
        case tab
        case other
    }

    let route: RoutingNodeType
    let kind: Kind

    public var description: String {
        """
        • route: \(route)
        • kind: \(kind)
        • ui: \(route.getPresentable())
        """
    }
}

/// Any `RoutingNode` object.
/// Hierarchy of `RoutingNodeType` objects forms an app Coordinator.
public protocol RoutingNodeType {
    var uuid: String { get }

    /// Returns `RoutingNode`s stack for provided Request.
    /// Configured for each respective `RoutingNode` type.
    var testRequest: (_ request: RoutingRequestType, _ routers: [RoutingNodeType], _ condition: (RoutingNodeType) -> Bool, _ badUUIDs: inout [String: Bool]) -> [RoutingNodeType] { get }

    /// Passes actions to the Presenter to update the view for provided Request.
    /// Configured for each respective `RoutingNode` type.
    var performRequest: (_ request: RoutingRequestType, _ routers: [RoutingNodeType], _ options: [DispatchRouteOption], _ condition: @escaping ((RoutingNodeType) -> Bool)) -> Void { get }

    /// Array of nested `RoutingNode`s, i.e. modals.
    var substack: [RoutingNodeType]? { get set }

    /// Called when the `RoutingNode` is required to dismiss its substack.
    func dismissSubstack()

    /// Called when the `RoutingNode` does not handle a Request anymore.
    func unwind()

    /// The Presentable to return if this `RoutingNode` matches the Request.
    /// - returns: A Presentable object.
    func getPresentable() -> UIViewController

    func isPresentableExists() -> Bool

    /// Determines should this `RoutingNode` or it's child handle the given Request.
    /// Configured for each respective `RoutingNode` type.
    var shouldHandleRoute: (_ request: RoutingRequestType, _ condition: (RoutingNodeType) -> Bool) -> Bool { get }

    /// Determines should this `RoutingNode` handle the given Request by itself.
    /// Configured for each respective `RoutingNode` type.
    var shouldHandleRouteExclusively: (_ request: RoutingRequestType) -> Bool { get }
}

/// The `RoutingNode` is a structure that collects functions together that are related to the same endpoint or intermidiate routing point.
/// Each `RoutingNode` also requires a Presenter, to which any required changes are passed.
public struct RoutingNode<Presenter: RoutePresenterType>: RoutingNodeType {
    public let uuid: String

    /// Primary initializer for a `RoutingNode`.
    /// - parameter presenter: A Presenter object to pass UI changes to.
    public init(uuid: String = UUID().uuidString, _ presenter: Presenter) {
        self.uuid = uuid
        self.presenter = presenter
    }

    /// Presenter to pass UI changes to.
    internal fileprivate(set) var presenter: Presenter

    public func getPresentable() -> UIViewController {
        return presenter.getPresentable()
    }

    public func isPresentableExists() -> Bool {
        presenter.isPresentableExists()
    }

    public var substack: [RoutingNodeType]?

    public fileprivate(set) var shouldHandleRoute: (_ request: RoutingRequestType, _ condition: (RoutingNodeType) -> Bool) -> Bool
        = { _, _ in false }

    public fileprivate(set) var shouldHandleRouteExclusively: (_ request: RoutingRequestType) -> Bool = { _ in false }

    public fileprivate(set) var testRequest: (RoutingRequestType, [RoutingNodeType], (RoutingNodeType) -> Bool, inout [String: Bool]) -> [RoutingNodeType] = { _, _, _, _ in [] }

    public fileprivate(set) var performRequest: (_ request: RoutingRequestType, _ routers: [RoutingNodeType], _ options: [DispatchRouteOption], _ condition: @escaping ((RoutingNodeType) -> Bool)) -> Void
        = { _, _, _, _ in }

    public func dismissSubstack() {
        dispatchOnMainThreadIfNeeded {
            if let modal = self.substack?.first?.getPresentable(), let presenter = self.presenter as? RoutePresenterCapableOfModalPresentationType {
                presenter.dismissModal(modal)
            }
        }
    }

    public func unwind() {
        dismissSubstack()

        dispatchOnMainThreadIfNeeded {
            self.presenter.unwind(self.presenter.getPresentable())
        }
    }
}

extension RoutingNode where Presenter == RoutePresenter {
    /// Endpoint `RoutingNode` represents an actual target to navigate to, configured with `RouteParameters` based on `RoutingRequest`.
    /// - parameter isMatching: A closure to determine whether this `RoutingNode` should handle the Request.
    /// - parameter resolve: A closure to resolve the Request based on Route to configure a Presentable with.
    /// - parameter children: `RoutingNode`s you can navigate to from this unit, i.e. in navigation stack.
    /// - parameter modals: `RoutingNode`s you can present as modals from this one.
    /// - returns: Modified `RoutingNode`
    public func endpoint(
        isMatching: @escaping ((_ request: RoutingRequestType) -> Bool),
        resolve: @escaping ((_ request: RoutingRequestType) -> RoutingResolvedRequestType),
        children: [RoutingNodeType] = [],
        modals: [RoutingNodeType] = []
    ) -> RoutingNode {
        var router = self

        router.shouldHandleRoute = { request, condition in
            // checking if this RoutingNode or any of the children or modals can handle the Request
            (isMatching(request) && condition(self))
                || children.contains { $0.shouldHandleRoute(request, condition) }
                || modals.contains { $0.shouldHandleRoute(request, condition) }
        }

        router.shouldHandleRouteExclusively = { request in
            isMatching(request)
        }

        router.testRequest = { request, routers, condition, badUUIDs in
            router.substack = nil

            if badUUIDs[router.uuid] != nil {
                return routers
            }
            badUUIDs[router.uuid] = true
            
            // this RoutingNode handles the Request
            if isMatching(request) && condition(self) {
                return routers + [router]
            }

            // should present a modal to handle the Request
            else if let modal = modals.firstResult({ modal in modal.shouldHandleRoute(request, condition) ? modal : nil })
            {
                router.substack = modal.testRequest(request, routers, condition, &badUUIDs)
//                return modal.testRequest(request, routers + [router], condition)
                return routers + [router]
            }

            // this RoutingNode's child handles the Request
            else if let child = children.firstResult({ child in child.shouldHandleRoute(request, condition) ? child : nil })
            {
                return child.testRequest(request, routers + [router], condition, &badUUIDs)
            }

            return routers
        }

        router.performRequest = { request, routers, dispatchOptions, condition in

            // this RoutingNode handles the Request
            if isMatching(request) && condition(self) {
                dispatchOnMainThreadIfNeeded {
                    let presentable = router.getPresentable()

                    //
                    // setting parameters
                    let resolvedRequest = resolve(request)
                    let routeParameters = RouteParameters(request: resolvedRequest)
                    router.presenter.setParameters(routeParameters, presentable)
                }
            }

            // should present a modal to handle the Request
            else if let modal = modals.firstResult({ modal in modal.shouldHandleRoute(request, condition) ? modal : nil })
            {
                dispatchOnMainThreadIfNeeded {
                    let modalPresentable = modal.getPresentable()
                    if modalPresentable.presentingViewController == nil {
                        let presentable = router.getPresentable()
                        router.presenter.presentModal(modalPresentable, presentable)
                    }
                }

//                modal.performRequest(request, routers + [router], dispatchOptions, condition)
                modal.performRequest(request, [], dispatchOptions, condition)
            }

            // this RoutingNode's child handles the Request
            else if let child = children.firstResult({ child in child.shouldHandleRoute(request, condition) ? child : nil })
            {
                child.performRequest(request, routers + [router], dispatchOptions, condition)
            }

            // this RoutingNode cannot handle the Request
            else { }
        }
        
        return router
    }

    /// Convenience method for Endpoint `RoutingNode` creation, `route` is checked for match with default rules.
    /// Endpoint `RoutingNode` represents an actual target to navigate to, configured with `RouteParameters` based on `RoutingRequest`.
    /// - parameter route: A `RouteType` to determine whether this `RoutingNode` should handle the Request.
    /// - parameter children: `RoutingNode`s you can navigate to from this unit, i.e. in navigation stack.
    /// - parameter modals: `RoutingNode`s you can present as modals from this one.
    /// - returns: Modified `RoutingNode`
    public func endpoint(
        _ route: RouteType,
        children: [RoutingNodeType] = [],
        modals: [RoutingNodeType] = []
    ) -> RoutingNode {
        endpoint(isMatching: { route.isMatching(request: $0) }, resolve: { $0.resolve(for: route) }, children: children, modals: modals)
    }
}

extension RoutingNode where Presenter == RoutePresenterStack {
    /// Stack `RoutingNode` can be used to organize other `RoutingNode`s in a navigation stack.
    /// - parameter stack: `RoutingNode`s in this navigation stack.
    /// - returns: Modified `RoutingNode`
    public func stack(_ stack: [RoutingNodeType]) -> RoutingNode {
        var router = self

        router.shouldHandleRoute = { request, condition in
            // checking if any of the children can handle the Request
            stack.contains { subRouter in subRouter.shouldHandleRoute(request, condition) }
        }

        router.shouldHandleRouteExclusively = { request in
            stack.first?.shouldHandleRouteExclusively(request) ?? false
        }

        router.testRequest = { request, routers, condition, badUUIDs in
            
            if badUUIDs[router.uuid] != nil {
                return routers + [router]
            }
            badUUIDs[router.uuid] = true
            
            // some item in stack handles the Request
            if let stackItem = stack.firstResult({ stackItem in stackItem.shouldHandleRoute(request, condition) ? stackItem : nil })
            {
                let stackRouters = stackItem.testRequest(request, [], condition, &badUUIDs)
                return routers + [router] + stackRouters
            }

            // no item found
            return routers + [router]
        }

        router.performRequest = { request, _, dispatchOptions, condition in

            // `junctionsOnly` dispatch option
            if dispatchOptions.contains(.junctionsOnly) {
                // some item in the stack handles the Request
                if let stackItem = stack.firstResult({ stackItem in stackItem.shouldHandleRoute(request, condition) ? stackItem : nil })
                {
                    dispatchOnMainThreadIfNeeded {
                        let presentable = router.presenter.getPresentable()
                        router.presenter.prepareRootPresentable(stackItem.getPresentable(), presentable)
                    }
                    stackItem.performRequest(request, [], dispatchOptions, condition)
                }
                return
            }

            // default dispatch options

            // some item in the stack handles the Request
            if let stackItem = stack.firstResult({ stackItem in stackItem.shouldHandleRoute(request, condition) ? stackItem : nil })
            {
                dispatchOnMainThreadIfNeeded {
                    let presentable = router.presenter.getPresentable()
                    router.presenter.prepareRootPresentable(stackItem.getPresentable(), presentable)

                    var badUUIDs = [String: Bool]()
                    var stackRouters = stackItem.testRequest(request, [], condition, &badUUIDs)

                    for i in 0 ..< stackRouters.count {
                        if (stackRouters[i].substack?.count ?? 0) > 0 {
                            stackRouters = Array(stackRouters.prefix(i + 1))
                            break
                        }
                    }

                    // passing the navigation stack to the Presenter
                    router.presenter.setStack(stackRouters.map({ subRouter in subRouter.getPresentable() }), presentable)
                }

                stackItem.performRequest(request, [], dispatchOptions, condition)
            }

            // no item found
            else { }
        }

        return router
    }
}

extension RoutingNode where Presenter == RoutePresenterFork {
    /// Fork `RoutingNode` can be used for tabbar-like navigation.
    /// - parameter options: `RoutingNode`s in this navigation set.
    /// - returns: Modified `RoutingNode`
    public func fork(_ options: [RoutingNodeType]) -> RoutingNode {
        var router = self

        router.shouldHandleRoute = { request, condition in
            // checking if any of the children can handle the Request
            options.contains { option in option.shouldHandleRoute(request, condition) }
        }

        router.testRequest = { request, routers, condition, badUUIDs in

            if badUUIDs[router.uuid] != nil {
                return routers + [router]
            }
            badUUIDs[router.uuid] = true

            // this RoutingNode's option handles the Request
            if let option = options.firstResult({ option in option.shouldHandleRoute(request, condition) ? option : nil })
            {
                return option.testRequest(request, routers + [router], condition, &badUUIDs)
            }

            // no option found
            return routers + [router]
        }

        router.performRequest = { request, routers, dispatchOptions, condition in
            let presentable = router.presenter.getPresentable()

            // passing children as options for the Presenter
            dispatchOnMainThreadIfNeeded {
                router.presenter.setOptions(options.map { option in option.getPresentable() }, presentable)
            }

            // this RoutingNode's option handles the Request
            if let option = options.firstResult({ option in option.shouldHandleRoute(request, condition) ? option : nil })
            {
                // setup the Presenter for matching RoutingNode and set it as an active option
                dispatchOnMainThreadIfNeeded {
                    router.presenter.setOptionSelected(option.getPresentable(), presentable)
                }

                // `junctionsOnly` dispatch option
                // keep presented VCs if we only need to switch option
                if dispatchOptions.contains(.junctionsOnly),
                   option.shouldHandleRouteExclusively(request)
                {
                    option.performRequest(request, routers + [router], dispatchOptions, condition)
                    return
                }

                // default dispatch options
                // perform new Request
                option.performRequest(request, routers + [router], dispatchOptions, condition)
            }

            // no option found
            else { }
        }

        return router
    }
}

extension RoutingNode where Presenter == RoutePresenterSwitcher {
    /// Switcher `RoutingNode` can be used to switch sections of your app, like onboarding/login/main, by the means of changing `rootViewController` of a window or similar.
    /// This RoutingNode's Presenter doesn't have an actual view.
    /// - parameter options: `RoutingNode`s in this navigation set.
    /// - returns: Modified `RoutingNode`
    public func switcher(_ options: [RoutingNodeType]) -> RoutingNode {
        var router = self

        router.shouldHandleRoute = { request, condition in
            // checking if any of the children can handle the Request
            options.contains { option in option.shouldHandleRoute(request, condition) }
        }

        router.testRequest = { request, routers, condition, badUUIDs in

            if badUUIDs[router.uuid] != nil {
                return routers + [router]
            }
            badUUIDs[router.uuid] = true

            // finding an option to handle the Request
            if let option = options.firstResult({ option in option.shouldHandleRoute(request, condition) ? option : nil })
            {
                return option.testRequest(request, routers + [router], condition, &badUUIDs)
            }

            // no option found
            return routers + [router]
        }

        router.performRequest = { request, routers, dispatchOptions, condition in
            // finding an option to handle the Request
            if let option = options.firstResult({ option in option.shouldHandleRoute(request, condition) ? option : nil })
            {
                // setup the presenter for matching Router and set it as an active option
                dispatchOnMainThreadIfNeeded {
                    router.presenter.setOptionSelected(option.getPresentable())
                }
                option.performRequest(request, routers + [router], dispatchOptions, condition)
            }

            // no option found
            else { }
        }

        return router
    }
}

func dispatchOnMainThreadIfNeeded(closure: @escaping () -> Void) {
    if Thread.isMainThread {
        closure()
    } else {
        DispatchQueue.main.async {
            closure()
        }
    }
}

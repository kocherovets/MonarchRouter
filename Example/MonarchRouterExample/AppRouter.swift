//
//  RoutingUnit.swift
//  MonarchRouterExample
//
//  Created by Eliah Snakin on 16/11/2018.
//  nikans.com
//

import Foundation
import MonarchRouter


/// Your app custom Routes enum and Paths for them.
enum AppRoute
{
    case login
    case onboarding(name: String)
    case first
    case firstDetail
    case firstDetailParametrized(id: String)
    case second
    case secondDetail
    case third(id: String)
    case fourth(id: String)
    case fifth
    case modal
    case modalParametrized(id: String)
    
    var path: String {
        switch self {
        case .login:                            return "login"
        case .onboarding(let name):             return "onboarding/" + name
        case .first:                            return "first"
        case .firstDetail:                      return "firstDetail"
        case .firstDetailParametrized(let id):  return "firstDetailParametrized/" + id
        case .second:                           return "second"
        case .secondDetail:                     return "secondDetail"
        case .third(let id):                    return "third/" + id
        case .fourth(let id):                   return "fourth/" + id
        case .fifth:                            return "fifth"
        case .modal:                            return "modal"
        case .modalParametrized(let id):        return "modalParametrized/" + id
        }
    }
}


/// Sets up the Router and root view controller.
func appRouter(setRootView: @escaping (UIViewController)->())
{
    var router: RoutingUnitType!
    
    // creating a Store for the Router and passing a callback to get a Coordinator (RoutingUnits hierarchy) to it
    let store = RouterStore(router: router)
    
    // creating a Coordinator hierarchy for the Router
    router = createCoordinator(dispatcher: store, setRootView: setRootView)
    
    // presenting the default Route
    store.dispatchRoute(.login)
}


/// Describes the object capable of Routes switching.
protocol ProvidesRouteDispatch
{
    /// Extension method to change the route.
    /// - parameter route: `AppRoute` to navigate to.
    func dispatchRoute(_ route: AppRoute)
    
    /// Extension method to change the route.
    /// - parameter route: `AppRoute` to navigate to.
    /// - parameter options: Special options for navigation (see `DispatchRouteOption` enum).
    func dispatchRoute(_ route: AppRoute, options: [DispatchRouteOption])
}

// Extending `RouterStore` to accept `AppRoute` instead of string Path.
extension RouterStore: ProvidesRouteDispatch
{
    func dispatchRoute(_ route: AppRoute) {
        dispatchRoute(route.path)
    }
    
    func dispatchRoute(_ route: AppRoute, options: [DispatchRouteOption]) {
        dispatchRoute(route.path, options: options)
    }
}
